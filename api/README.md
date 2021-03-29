
# API Ar Redadeg


## À propos

Cette API sert à…


## Installation

### Hello.py

	cd api
	python3 -m venv venv
	. venv/bin/activate
	pip install flask uwsgi

tester
	python3 hello.py

Vérifier sur http://localhost:5000/

ctrl + C pour arrêter

### Configurer uWSGI

On utilise les fichiers wsgi.py et hello.ini

on teste si uWSGI et le socket fonctionne :

	uwsgi -s /tmp/hello.sock --manage-script-name --mount /hello=wsgi:app


### Configurer nginx

On rajoute les directives suivantes au fichier de conf nginx

    location = /hello { rewrite ^ /hello/; }
    location /hello { try_files $uri @hello; }
    location @hello {
      include uwsgi_params;
      uwsgi_pass unix:/tmp/hello.sock;
    }

Recharger la configuration nginx.

Tester  http://ar-redadeg.openstreetmap.bzh/hello/

Super ! Mais il faut que la commande uwsgi -s qui crée le socket soit active dans le shell.


### sortir 

deactivate



## Sources

https://flask.palletsprojects.com/en/1.1.x/deploying/uwsgi/

https://www.vultr.com/docs/deploy-a-flask-website-on-nginx-with-uwsgi

https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-uswgi-and-nginx-on-ubuntu-18-04