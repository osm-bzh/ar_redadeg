#!usr/local/bin/python
# -*- coding: utf-8 -*-

from flask import Flask


app = Flask(__name__)


@app.route("/")
def hello():
    return "<h1 style='color:blue'>Hello There!</h1>"

@app.route("/about/")
def about():
    return "This is a simple Flask Python application"

if __name__ == "__main__":
    app.debug = True
    app.run(host='0.0.0.0')
