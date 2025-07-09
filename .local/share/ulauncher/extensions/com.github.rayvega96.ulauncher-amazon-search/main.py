#    Ulauncher extension to provide a quick search on amazon website.
#    Copyright (C) <2022>  <Francesco Emanuele Conti>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.


from ulauncher.api.client.Extension import Extension
from ulauncher.api.client.EventListener import EventListener
from ulauncher.api.shared.event import KeywordQueryEvent, ItemEnterEvent
from ulauncher.api.shared.item.ExtensionResultItem import ExtensionResultItem
from ulauncher.api.shared.action.RenderResultListAction import RenderResultListAction
from ulauncher.api.shared.action.HideWindowAction import HideWindowAction
from ulauncher.api.shared.action.OpenUrlAction import OpenUrlAction

from bs4 import BeautifulSoup
import requests
from time import sleep

class Product:
    def __init__(self, link, name, rating, rating_count, price) -> None:
        self.link = link
        self.name = name
        self.rating = rating
        self.rating_count = rating_count
        self.price = price
    
    def getLink(self):
        return self.link
    def getName(self):
        return self.name
    def getRating(self):
        return self.rating
    def getRatingCount(self):
        return self.rating_count
    def getPrice(self):
        return self.price

headers = {'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:107.0) Gecko/20100101 Firefox/107.0'}

websites_dictionary = {
        "amzit":   "https://www.amazon.it/s?k=",
        "amzuk":   "https://www.amazon.co.uk/s?k=",
        "amzsp":   "https://www.amazon.es/s?k=",
        "amznl":   "https://www.amazon.nl/s?k=",
        "amzus":   "https://www.amazon.com/s?k=",
        "amzmx":   "https://www.amazon.com.mx/s?k=",
        "amzca":   "https://www.amazon.ca/s?k=",
        "amzge":   "https://www.amazon.de/s?k=",
        "amzfr":   "https://www.amazon.fr/s?k=",
        "amzjp":   "https://www.amazon.co.jp/s?k=",
        "amzbr":   "https://www.amazon.com.br/s?k=",
        "amzau":   "https://www.amazon.com.au/s?k=",
        "amzin":   "https://www.amazon.in/s?k=",
        "amzcn":   "https://www.amazon.cn/s?k="  
    }

websites_icon_dictionary = {
        "amzit":   "italy",
        "amzuk":   "uk",
        "amzsp":   "spain",
        "amznl":   "netherlands",
        "amzus":   "us",
        "amzmx":   "mexico",
        "amzca":   "canada",
        "amzge":   "germany",
        "amzfr":   "france",
        "amzjp":   "japan",
        "amzbr":   "brazil",
        "amzau":   "australia",
        "amzin":   "india",
        "amzcn":   "china"
    }

websites_domain_dictionary = {
        "it":   "amzit",
        "uk":   "amzuk",
        "sp":   "amzsp",
        "nl":   "amznl",
        "us":   "amzus",
        "mx":   "amzmx",
        "ca":   "amzca",
        "ge":   "amzge",
        "fr":   "amzfr",
        "jp":   "amzjp",
        "br":   "amzbr",
        "au":   "amzau",
        "in":   "amzin",
        "cn":   "amzcn"
    }

def research_products(amazon_link, search_query):

            query_formatted = search_query.lower().rstrip(".").split()

            amazon_argument = search_query.replace(" ", "+").rstrip(".")

            print("[Amazon Search] Research: " + amazon_link+amazon_argument+"&page1")

            #Dividiamo i prodotti in base alla query inserita:
            # - Se tutti i termini della query sono presenti nella descrizione del prodotto -> verified_products
            # - Se non tutti i termini sono presenti -> general_products
            general_products = []
            verified_products = []

            response = requests.get(amazon_link+amazon_argument+"&page1", headers=headers, stream=False)

            soup = BeautifulSoup(response.content, 'html.parser')
            response_code = response.status_code
            response.close()

            if response_code == 503:
                return '503'
            else:
            
                results = soup.find_all('div', {'class': 's-result-item', 'data-component-type': 's-search-result'})
                print("[Amazon Search] Research: Found "+str(len(results))+" results.")
                for result in results:
                    product_name = result.h2.text
                    product_url = amazon_link.rstrip("/s?k=") + result.h2.a['href']
                    
                    #Prelevo il rating su 5 stelle del prodotto
                    try: 
                        rating = result.find('i', {'class': 'a-icon'}).text
                        rating = rating.replace("su", "/")
                    except AttributeError:
                        rating = "No Rating"
                        continue
                    
                    #Prelevo il numero di acquisti del prodotto
                    try:
                        rating_count = result.find('span', {'class': 'a-size-base'}).text
                        rating_count = rating_count.replace(".", "")
                        rating_count = int(rating_count)
                    except AttributeError:
                        rating_count = 0
                    except ValueError:
                        rating_count = 0
                        continue

                    #Prelevo il prezzo del prodotto
                    try:
                        price = result.find('span', {'class': 'a-price-whole'}).text
                        price_symbol = result.find('span', {'class': 'a-price-symbol'}).text
                    except AttributeError:
                        price = "No Price"
                        price_symbol = ""
                        continue

                    #Verifico se il prodotto appartiene alle due categorie: general o verified
                    flagOK = True
                    for split in query_formatted:
                        if split in product_name.lower():
                            continue
                        else:
                            flagOK = False
                            break
                    if flagOK and next((x for x in verified_products if x.getName() != product_name), None) is None:
                        verified_products.append(Product(product_url, product_name[0:40], rating, rating_count, f"{price} {price_symbol}"))
                    else:
                        general_products.append(Product(product_url, product_name[0:40], rating, rating_count, f"{price} {price_symbol}"))
                
                #Ordino i prodotti in base al numero di recensioni fornite
                verified_products.sort(key=lambda x: x.rating_count, reverse=True)
                general_products.sort(key=lambda x: x.rating_count, reverse=True)

            print("[Amazon Search] Research: Retrieving FIVE most rated items.")
            #Ritorno una lista di prodotti:
            # - Se i verified_product sono almeno 5, ritorno solo quelli
            # - Altrimenti inserisco i general_products con maggiore rating in modo da arrivare comunque a 5
            if len(verified_products) > 4:
                return verified_products[0:5]
            else:
                return verified_products + general_products[0:(4 - len(verified_products))]




class Amazon_Search(Extension):

    def __init__(self):
        super().__init__()
        self.subscribe(KeywordQueryEvent, KeywordQueryEventListener())

class KeywordQueryEventListener(EventListener):

    def on_event(self, event, extension):

        multi_amazon = extension.preferences.get('multiamazon') == 'Yes'
        fast_search = extension.preferences.get('fastsearch') == 'Yes'
        fast_commands = extension.preferences.get('fastcommands') == 'Yes'

        argument = (event.get_argument() or '')
        website = ""
        description = ""

        items = []


        anything_wrong = False
        
        #Se la ricerca su piu' siti amazon non e' abilitata, imposto sito e icona da impostazioni di default.
        if not multi_amazon:

            website = websites_dictionary[extension.preferences.get('defaultwebsite')]
            description = websites_icon_dictionary[extension.preferences.get('defaultwebsite')]

        #Se la ricerca e' abilitata provo a recuperare il dominio di attivita' ed impostare sito e icona.
        #se non ci riesco rimando un errore di parametro non valido.
        else:

            try:
                if argument.startswith("-") and len(argument) > 2:
                    arguments = argument.split()
                    domain = arguments[0].lstrip("-")  
        
                    website = websites_dictionary[websites_domain_dictionary[domain]]
                    description = websites_icon_dictionary[websites_domain_dictionary[domain]]

                    argument = argument.replace(f"-{domain}", "")
                    argument = argument.lstrip()
                else:
                    website = websites_dictionary[extension.preferences.get('defaultwebsite')]
                    description = websites_icon_dictionary[extension.preferences.get('defaultwebsite')]
                    
            except KeyError:
                website = websites_dictionary[extension.preferences.get('defaultwebsite')]
                description = 'Parameter not accepted'
                items.append(ExtensionResultItem(icon='images/icon.ico', name="Parameter not accepted", description="Check documentation for a list of accepted parameters", highlightable=False))
                anything_wrong = True

        #Parametri rapidi

        if '-myprofile' in argument and fast_commands:
            website = website.replace("s?k=", "")
            items.append(ExtensionResultItem(icon=f'images/profile.ico', name="My Profile", description=website+"gp/css/homepage.html", on_enter=OpenUrlAction(website+"gp/css/homepage.html"), highlightable=False))
        
        elif '-myorders' in argument and fast_commands:
            website = website.replace("s?k=", "")
            items.append(ExtensionResultItem(icon=f'images/orders.ico', name="My Orders", description=website+"gp/your-account/order-history", on_enter=OpenUrlAction(website+"gp/your-account/order-history"), highlightable=False))

        elif '-mymessages' in argument and fast_commands:
            website = website.replace("s?k=", "")
            items.append(ExtensionResultItem(icon=f'images/messages.ico', name="My Messages", description=website+"gp/message", on_enter=OpenUrlAction(website+"gp/message"), highlightable=False))

        elif '-mybalance' in argument and fast_commands:
            website = website.replace("s?k=", "")
            items.append(ExtensionResultItem(icon=f'images/balance.ico', name="My Balance", description=website+"gp/css/gc/balance", on_enter=OpenUrlAction(website+"gp/css/gc/balance"), highlightable=False))

        #Ricerca normale
        elif not anything_wrong:
            items.append(ExtensionResultItem(icon=f'images/{description}.ico', name=str(argument), description=website+str(argument).rstrip(".").replace(" ","+"), on_enter=OpenUrlAction(website+str(argument).rstrip(".").replace(" ","+")), highlightable=False))
        

        #Implementazione FastSearch
        if argument.endswith(".") and fast_search and not anything_wrong:
            
            max_seconds = int(extension.preferences.get('wait_seconds'))

            counter_of_tries = 0

            for i in range(1,max_seconds+1):

                products = research_products(website, argument)

                if(products != '503'):
                    break
                else:
                    print(f"[Amazon Search]: Received 503 Status code. {i}/{max_seconds} attempt.")
                    sleep(1)

            if products == '503':
                print(f"[Amazon Search]: {counter_of_tries}/{max_seconds} Attempt: Impossible to retrieve research information.")
                items.append(ExtensionResultItem(icon=f'images/{description}.ico', name="Received 503 Status Code: Service Unavailable", description="Amazon is trying to prevent flooding. Try again later.", highlightable=False))
            else:

                for product in products:
                    items.append(ExtensionResultItem(icon=f'images/{description}.ico', name=product.getName(), description="⭐" + product.getRating() + "⭐" + "    🧑"+str(product.getRatingCount())+ "🧑    💵"+product.getPrice()+"💵", on_enter=OpenUrlAction(product.getLink()), highlightable=False))
        
        return RenderResultListAction(items)





if __name__ == '__main__':
    Amazon_Search().run()