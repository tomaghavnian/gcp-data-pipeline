from datetime import datetime, timezone
import os
import requests
import gzip
import io
import pandas as pd
from google.cloud import storage

def download_noaa_csv(request=None):
    """
    Télécharge le CSV NOAA GHCN Daily de l'année courante,
    prétraite les colonnes principales et upload dans GCS.
    """
    # Année actuelle
    year = datetime.now().year
    url = f"https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/by_year/{year}.csv.gz"

    print(f"Downloading NOAA data for {year}...")
    response = requests.get(url)
    response.raise_for_status()

    # Lire le CSV gzip
    with gzip.open(io.BytesIO(response.content), mode='rt') as f:
        df = pd.read_csv(f, header=None)

    # Ajouter les 8 colonnes officielles du fichier NOAA
    df.columns = [
        "station_id",
        "observation_date",
        "element",
        "value",
        "m_flag",
        "q_flag",
        "s_flag",
        "obs_time"
    ]

    # Garder seulement les colonnes principales pour le pipeline
    df_clean = df[["station_id","observation_date","element","value"]]

    # Pivot pour temperature et precipitation
    temp_df = df_clean[df_clean["element"].isin(["TMAX","TMIN"])].copy()
    prcp_df = df_clean[df_clean["element"] == "PRCP"].copy()

    # Calculer température moyenne si TMAX/TMIN disponibles
    temp_df = temp_df.pivot_table(
        index=["station_id","observation_date"],
        columns="element",
        values="value"
    ).reset_index()
    temp_df["temperature"] = ((temp_df.get("TMAX",0) + temp_df.get("TMIN",0)) / 2).round(1)
    temp_df = temp_df[["station_id","observation_date","temperature"]]

    # Préparer précipitation
    prcp_df = prcp_df[["station_id","observation_date","value"]].rename(columns={"value":"precipitation"})

    # Merge temperature + precipitation
    merged = pd.merge(temp_df, prcp_df, on=["station_id","observation_date"], how="outer")

    # Convertir la date YYYYMMDD → YYYY-MM-DD
    merged["observation_date"] = pd.to_datetime(merged["observation_date"], format="%Y%m%d").dt.date

    # Sauvegarde en gzip mémoire
    out_buffer = io.BytesIO()
    with gzip.GzipFile(fileobj=out_buffer, mode='w') as gz:
        merged.to_csv(io.TextIOWrapper(gz, encoding='utf-8'), index=False)

    # Upload vers GCS
    project_id = os.getenv("PROJECT_ID", "prime-hour-472917-d3")
    client = storage.Client(project=project_id)
    bucket = client.bucket(f"{project_id}-raw-weather")
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    filename = f"noaa_{today}-clean.csv.gz"
    blob = bucket.blob(f"raw/{filename}")
    blob.upload_from_string(out_buffer.getvalue())

    print(f"Uploaded cleaned file {filename} to GCS.")
    return filename

if __name__ == '__main__':
    download_noaa_csv()
