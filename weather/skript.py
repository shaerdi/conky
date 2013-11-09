#!/usr/bin/env python

from lxml import etree
import time,os,sys,shutil

location = 'Chur'

url = 'http://api.openweathermap.org/data/2.5/forecast/daily?q='+location+'&cnt=3&mode=xml&units=metric'

parsed = etree.parse(url)

loc = parsed.find('location').getchildren()[0].text
print loc

fc = parsed.find('forecast').getchildren()

num = len(fc)

dates = [d.values()[0] for d in fc]
days = [time.strftime('%a',time.strptime(t,'%Y-%m-%d')) for t in dates]

syms = [f[0].attrib['var'] for f in fc]
names = [f[0].attrib['name'] for f in fc]

tempsMax = [float(f[4].attrib['max']) for f in fc]
tempsMin = [float(f[4].attrib['min']) for f in fc]

tempsMax = ['{: >6.2f} C'.format(t) for t in tempsMax]
tempsMin = ['{: >6.2f} C'.format(t) for t in tempsMin]

pathname = os.path.dirname(sys.argv[0])
path = os.path.abspath(pathname)

def ensure_dir(f):
    d = os.path.dirname(f)
    if not os.path.exists(d):
        os.makedirs(d)

ensure_dir(path+'/data/')
ensure_dir(path+'/pics/current/')

for i,pic in enumerate(syms):
    try:
        shutil.copy(path+'/pics/'+pic+'.png', path+'/pics/current/' + str(i))
    except IOError:
        shutil.copy(path+'/pics/err.png', path+'/pics/current/' + str(i))


with open(path+'/data/testout','w') as myFile:
    for d in zip(days,names,tempsMin,tempsMax):
        myFile.write(','.join(d))
        myFile.write('\n')

#print 'test'
#print ','.join(map(str,tempsMax))
