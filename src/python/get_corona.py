import pandas as pd
from urllib.request import Request, urlopen, urlretrieve
import requests

sheets = ['Tageswerte berechnet', 'Fälle-Todesfälle-gesamt', 'BL_7-Tage-Fallzahlen', 'BL_7-Tage-Inzidenz']
link_rki_corona = 'https://www.rki.de/DE/Content/InfAZ/N/Neuartiges_Coronavirus/Daten/Fallzahlen_Kum_Tab.xlsx'
user_agent = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:82.0) Gecko/20100101 Firefox/82.0'}

resp = requests.get(link_rki_corona, headers=user_agent)

urlretrieve(link_rki_corona, 'test.xlsx')
req = Request(link_rki_corona)
req.add_header('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:82.0) Gecko/20100101 Firefox/82.0')
content = urlopen(req)

data = pd.read_excel(content, sheets[0])

print(data)

