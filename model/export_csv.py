import os
from fetch_data import fetch_all

os.makedirs("data", exist_ok=True)

data = fetch_all()
for name, df in data.items():
    df.to_csv(f"data/{name}.csv", index=False)
    print(f"Exported {name}: {len(df)} rows → data/{name}.csv")
