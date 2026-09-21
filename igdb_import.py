"""Load IGDB game data into the MySQL staging table used by this project."""

from __future__ import annotations

import getpass
import logging
import os
import re
import time
from datetime import datetime, timezone
from typing import Any, Iterable

import pymysql
import requests
from dotenv import load_dotenv


IGDB_GAMES_URL = "https://api.igdb.com/v4/games"
TWITCH_TOKEN_URL = "https://id.twitch.tv/oauth2/token"
MAX_IGDB_PAGE_SIZE = 500
DEFAULT_TOTAL_GAMES = 1500
REQUEST_TIMEOUT_SECONDS = 30
MAX_REQUEST_ATTEMPTS = 5
UPSERT_BATCH_SIZE = 100

FIELDS = """
    id, name, slug, url, summary, storyline,
    rating, rating_count, aggregated_rating, aggregated_rating_count,
    total_rating, total_rating_count, first_release_date,
    status, category, hypes, follows,
    game_modes.name, genres.name, themes.name, keywords.name,
    platforms.name, platforms.abbreviation,
    player_perspectives.name,
    involved_companies.company.name,
    involved_companies.developer,
    involved_companies.publisher,
    cover.url, screenshots.url, videos.video_id,
    websites.url, websites.category,
    franchises.name, collections.name,
    age_ratings.rating, age_ratings.category,
    language_supports.language.name,
    language_supports.language_support_type.name,
    multiplayer_modes.onlinemax,
    multiplayer_modes.offlinemax,
    multiplayer_modes.campaigncoop,
    multiplayer_modes.lancoop,
    multiplayer_modes.onlinecoop,
    multiplayer_modes.splitscreen,
    game_engines.name, tags
"""

CREATE_STAGING_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS games (
    id                      INT PRIMARY KEY,
    name                    VARCHAR(512),
    slug                    VARCHAR(512),
    url                     VARCHAR(1024),
    summary                 TEXT,
    storyline               TEXT,
    rating                  FLOAT,
    rating_count            INT,
    aggregated_rating       FLOAT,
    aggregated_rating_count INT,
    total_rating            FLOAT,
    total_rating_count      INT,
    first_release_date      DATE,
    status                  INT,
    category                INT,
    hypes                   INT,
    follows                 INT,
    game_modes              TEXT,
    genres                  TEXT,
    themes                  TEXT,
    keywords                TEXT,
    platforms               TEXT,
    player_perspectives     TEXT,
    developers              TEXT,
    publishers              TEXT,
    cover_url               VARCHAR(1024),
    screenshots             TEXT,
    video_ids               TEXT,
    websites                TEXT,
    franchises              TEXT,
    collections             TEXT,
    age_ratings             TEXT,
    language_supports       TEXT,
    multiplayer_online_max  INT,
    multiplayer_offline_max INT,
    multiplayer_coop        TINYINT(1),
    game_engines            TEXT,
    tags                    TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
"""

UPSERT_GAME_SQL = """
INSERT INTO games (
    id, name, slug, url, summary, storyline,
    rating, rating_count, aggregated_rating, aggregated_rating_count,
    total_rating, total_rating_count, first_release_date,
    status, category, hypes, follows,
    game_modes, genres, themes, keywords, platforms, player_perspectives,
    developers, publishers, cover_url, screenshots, video_ids, websites,
    franchises, collections, age_ratings, language_supports,
    multiplayer_online_max, multiplayer_offline_max, multiplayer_coop,
    game_engines, tags
) VALUES (
    %s, %s, %s, %s, %s, %s,
    %s, %s, %s, %s,
    %s, %s, %s,
    %s, %s, %s, %s,
    %s, %s, %s, %s, %s, %s,
    %s, %s, %s, %s, %s, %s,
    %s, %s, %s, %s,
    %s, %s, %s,
    %s, %s
)
ON DUPLICATE KEY UPDATE
    name                    = VALUES(name),
    slug                    = VALUES(slug),
    url                     = VALUES(url),
    summary                 = VALUES(summary),
    storyline               = VALUES(storyline),
    rating                  = VALUES(rating),
    rating_count            = VALUES(rating_count),
    aggregated_rating       = VALUES(aggregated_rating),
    aggregated_rating_count = VALUES(aggregated_rating_count),
    total_rating            = VALUES(total_rating),
    total_rating_count      = VALUES(total_rating_count),
    first_release_date      = VALUES(first_release_date),
    status                  = VALUES(status),
    category                = VALUES(category),
    hypes                   = VALUES(hypes),
    follows                 = VALUES(follows),
    game_modes              = VALUES(game_modes),
    genres                  = VALUES(genres),
    themes                  = VALUES(themes),
    keywords                = VALUES(keywords),
    platforms               = VALUES(platforms),
    player_perspectives     = VALUES(player_perspectives),
    developers              = VALUES(developers),
    publishers              = VALUES(publishers),
    cover_url               = VALUES(cover_url),
    screenshots             = VALUES(screenshots),
    video_ids               = VALUES(video_ids),
    websites                = VALUES(websites),
    franchises              = VALUES(franchises),
    collections             = VALUES(collections),
    age_ratings             = VALUES(age_ratings),
    language_supports       = VALUES(language_supports),
    multiplayer_online_max  = VALUES(multiplayer_online_max),
    multiplayer_offline_max = VALUES(multiplayer_offline_max),
    multiplayer_coop        = VALUES(multiplayer_coop),
    game_engines            = VALUES(game_engines),
    tags                    = VALUES(tags);
"""


def required_env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise RuntimeError(
            f"Missing {name}. Copy .env.example to .env and provide a value."
        )
    return value


def positive_int_env(name: str, default: int) -> int:
    raw_value = os.getenv(name, str(default))
    try:
        value = int(raw_value)
    except ValueError as exc:
        raise RuntimeError(f"{name} must be an integer.") from exc
    if value <= 0:
        raise RuntimeError(f"{name} must be greater than zero.")
    return value


def validate_database_name(name: str) -> str:
    if not re.fullmatch(r"[A-Za-z0-9_]+", name):
        raise RuntimeError(
            "DB_NAME may contain only letters, numbers, and underscores."
        )
    return name


def post_with_retry(
    session: requests.Session,
    url: str,
    **kwargs: Any,
) -> requests.Response:
    """POST with bounded retries for rate limits and temporary server errors."""
    last_response: requests.Response | None = None

    for attempt in range(MAX_REQUEST_ATTEMPTS):
        try:
            response = session.post(
                url,
                timeout=REQUEST_TIMEOUT_SECONDS,
                **kwargs,
            )
        except requests.RequestException:
            if attempt == MAX_REQUEST_ATTEMPTS - 1:
                raise
            wait_seconds = 2**attempt
            logging.warning("Request failed; retrying in %s seconds.", wait_seconds)
            time.sleep(wait_seconds)
            continue

        last_response = response
        if response.status_code not in {429, 500, 502, 503, 504}:
            response.raise_for_status()
            return response

        if attempt == MAX_REQUEST_ATTEMPTS - 1:
            response.raise_for_status()

        retry_after = response.headers.get("Retry-After")
        wait_seconds = int(retry_after) if retry_after and retry_after.isdigit() else 2**attempt
        logging.warning(
            "IGDB returned HTTP %s; retrying in %s seconds.",
            response.status_code,
            wait_seconds,
        )
        time.sleep(wait_seconds)

    if last_response is not None:
        last_response.raise_for_status()
    raise RuntimeError("Request failed without receiving a response.")


def get_access_token(
    session: requests.Session,
    client_id: str,
    client_secret: str,
) -> str:
    response = post_with_retry(
        session,
        TWITCH_TOKEN_URL,
        params={
            "client_id": client_id,
            "client_secret": client_secret,
            "grant_type": "client_credentials",
        },
    )
    payload = response.json()
    token = payload.get("access_token")
    if not token:
        raise RuntimeError("Twitch authentication succeeded without returning a token.")
    return token


def fetch_games(
    session: requests.Session,
    headers: dict[str, str],
    total_games: int,
) -> list[dict[str, Any]]:
    games: list[dict[str, Any]] = []
    offset = 0

    while len(games) < total_games:
        page_size = min(MAX_IGDB_PAGE_SIZE, total_games - len(games))
        query = (
            f"fields {FIELDS};"
            "sort total_rating_count desc;"
            "where total_rating_count > 0;"
            f"limit {page_size};"
            f"offset {offset};"
        )

        response = post_with_retry(
            session,
            IGDB_GAMES_URL,
            headers=headers,
            data=query,
        )
        batch = response.json()
        if not isinstance(batch, list):
            raise RuntimeError("IGDB returned an unexpected response format.")
        if not batch:
            break

        games.extend(batch)
        offset += len(batch)
        logging.info("Fetched %s of %s requested games.", len(games), total_games)

        if len(batch) < page_size:
            break
        time.sleep(0.25)

    return games


def join_names(items: Any, key: str = "name") -> str | None:
    if not isinstance(items, list):
        return None
    values = [item.get(key, "") for item in items if isinstance(item, dict)]
    names = [str(value).strip() for value in values if value]
    return ", ".join(names) or None


def get_companies(companies: Any, role: str) -> str | None:
    if not isinstance(companies, list):
        return None
    names: list[str] = []
    for item in companies:
        if not isinstance(item, dict) or not item.get(role):
            continue
        company = item.get("company")
        if isinstance(company, dict) and company.get("name"):
            names.append(str(company["name"]).strip())
    return ", ".join(names) or None


def join_nested_values(items: Any, key: str) -> str | None:
    if not isinstance(items, list):
        return None
    values = [str(item[key]) for item in items if isinstance(item, dict) and item.get(key)]
    return ", ".join(values) or None


def release_date(timestamp: Any):
    if not isinstance(timestamp, (int, float)):
        return None
    return datetime.fromtimestamp(timestamp, tz=timezone.utc).date()


def game_to_row(game: dict[str, Any]) -> tuple[Any, ...]:
    multiplayer = game.get("multiplayer_modes")
    multiplayer_list = multiplayer if isinstance(multiplayer, list) else []
    first_multiplayer = (
        multiplayer_list[0]
        if multiplayer_list and isinstance(multiplayer_list[0], dict)
        else {}
    )
    multiplayer_coop = int(
        any(
            mode.get("campaigncoop")
            or mode.get("lancoop")
            or mode.get("onlinecoop")
            for mode in multiplayer_list
            if isinstance(mode, dict)
        )
    )

    age_ratings = game.get("age_ratings")
    age_rating_values = age_ratings if isinstance(age_ratings, list) else []
    age_rating_text = ", ".join(
        f"cat{item.get('category')}:{item.get('rating')}"
        for item in age_rating_values
        if isinstance(item, dict)
    ) or None

    language_supports = game.get("language_supports")
    language_values = language_supports if isinstance(language_supports, list) else []
    language_text: list[str] = []
    for item in language_values:
        if not isinstance(item, dict):
            continue
        language = item.get("language")
        support_type = item.get("language_support_type")
        if isinstance(language, dict) and isinstance(support_type, dict):
            if language.get("name") and support_type.get("name"):
                language_text.append(f"{language['name']}({support_type['name']})")

    cover = game.get("cover")
    cover_url = cover.get("url") if isinstance(cover, dict) else None

    return (
        game.get("id"),
        game.get("name"),
        game.get("slug"),
        game.get("url"),
        game.get("summary"),
        game.get("storyline"),
        game.get("rating"),
        game.get("rating_count"),
        game.get("aggregated_rating"),
        game.get("aggregated_rating_count"),
        game.get("total_rating"),
        game.get("total_rating_count"),
        release_date(game.get("first_release_date")),
        game.get("status"),
        game.get("category"),
        game.get("hypes"),
        game.get("follows"),
        join_names(game.get("game_modes")),
        join_names(game.get("genres")),
        join_names(game.get("themes")),
        join_names(game.get("keywords")),
        join_names(game.get("platforms")),
        join_names(game.get("player_perspectives")),
        get_companies(game.get("involved_companies"), "developer"),
        get_companies(game.get("involved_companies"), "publisher"),
        cover_url,
        join_nested_values(game.get("screenshots"), "url"),
        join_nested_values(game.get("videos"), "video_id"),
        join_nested_values(game.get("websites"), "url"),
        join_names(game.get("franchises")),
        join_names(game.get("collections")),
        age_rating_text,
        ", ".join(language_text) or None,
        first_multiplayer.get("onlinemax"),
        first_multiplayer.get("offlinemax"),
        multiplayer_coop,
        join_names(game.get("game_engines")),
        str(game.get("tags")) if game.get("tags") else None,
    )


def chunks(values: list[tuple[Any, ...]], size: int) -> Iterable[list[tuple[Any, ...]]]:
    for start in range(0, len(values), size):
        yield values[start : start + size]


def create_database(connection_settings: dict[str, Any], database_name: str) -> None:
    server_settings = dict(connection_settings)
    server_settings.pop("database", None)
    with pymysql.connect(**server_settings, autocommit=True) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"CREATE DATABASE IF NOT EXISTS `{database_name}` "
                "CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"
            )


def load_games(
    connection_settings: dict[str, Any],
    games: list[dict[str, Any]],
) -> int:
    rows = [game_to_row(game) for game in games]
    with pymysql.connect(**connection_settings, autocommit=False) as connection:
        try:
            with connection.cursor() as cursor:
                cursor.execute(CREATE_STAGING_TABLE_SQL)
                processed = 0
                for batch in chunks(rows, UPSERT_BATCH_SIZE):
                    cursor.executemany(UPSERT_GAME_SQL, batch)
                    processed += len(batch)
                    logging.info("Loaded %s of %s staging rows.", processed, len(rows))
            connection.commit()
        except Exception:
            connection.rollback()
            raise
    return len(rows)


def main() -> None:
    load_dotenv()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

    client_id = required_env("TWITCH_CLIENT_ID")
    client_secret = required_env("TWITCH_CLIENT_SECRET")
    database_name = validate_database_name(os.getenv("DB_NAME", "data_dogs"))
    total_games = positive_int_env("TOTAL_GAMES", DEFAULT_TOTAL_GAMES)

    password = os.getenv("DB_PASSWORD")
    if password is None:
        password = getpass.getpass("MySQL password: ")

    connection_settings: dict[str, Any] = {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": positive_int_env("DB_PORT", 3306),
        "user": os.getenv("DB_USER", "root"),
        "password": password,
        "database": database_name,
        "charset": "utf8mb4",
    }

    with requests.Session() as session:
        logging.info("Authenticating with Twitch.")
        token = get_access_token(session, client_id, client_secret)
        games = fetch_games(
            session,
            {
                "Client-ID": client_id,
                "Authorization": f"Bearer {token}",
            },
            total_games,
        )

    if not games:
        raise RuntimeError("IGDB returned no games; the database was not changed.")

    create_database(connection_settings, database_name)
    processed = load_games(connection_settings, games)
    logging.info("Finished: %s games inserted or updated in games.", processed)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, requests.RequestException, pymysql.MySQLError) as error:
        logging.error("Import failed: %s", error)
        raise SystemExit(1) from error
