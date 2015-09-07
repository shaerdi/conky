import urllib.request
import re
import os
import subprocess
class cluster:
    def __init__(self):
        self.linuxCallString = 'ssh haerdi@hpc01-server pbsnodes'
        self.fileloc = os.path.dirname(os.path.realpath(__file__)) + \
                       '/data/clusterStatus'
        self.nodeList = []
        self.getLinuxNodes()
        self.getWindowsNodes()
        self.saveFile()

    def getWindowsNodes(self):
        url = 'http://hpc01-server/cgi-bin/freenodes'
        page = urllib.request.urlopen(url).read().decode('utf8')
        page = page.replace(
                '<META HTTP-EQUIV="refresh" CONTENT="120">\n<br>',
                '')
        serverList = page.replace('\n','').replace('<br>','\n').split('\n\n')

        regex = re.compile('hpc(\d+)')

        numUsers = [
                    len([a for a in x.split('\n') if a!=''])-1 
                    for x in serverList
                   ]

        serverDict = dict(zip(
                        [
                         regex.findall(x)[0]
                         for x in serverList 
                         if len(regex.findall(x))>0
                        ], # Server Nr
                        numUsers  
                     ))

        for node in self.nodeList:
            server = node['number'] 
            if server in serverDict:
                node['state']=2
                node['nUsers'] = serverDict[server]

    def findAttribute(self,text,attribute):
        floatregex = '[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?'
        text = re.search(attribute+'\s?=\s?'+floatregex,text)
        if text is not None:
            text = text.group()
            text = text.replace(' ','')
            text = text.replace(attribute+'=','')
            return float(text)
        else:
            return None

    def getLinuxNodes(self):
        serverstatus = subprocess.check_output(
                                self.linuxCallString,
                                shell = True
                               ).decode('utf8')
        serverstatus = re.split('\n\s*\n',serverstatus)
        serverstatus = [s for s in filter(None,serverstatus)]
        self.numNodes = len(serverstatus)
        for node in serverstatus:
            states = re.search('state.*\n',node).group()
            states = states.replace('state = ','').strip().split(',')
            regex = re.compile('hpc(\d+)') 
            number = regex.findall(node)[0]
            #state = states.count('offline') + states.count('down')
            if not 'down' in states:
                state = 1
                offline = 'offline' in states
                ncpus = self.findAttribute(node,'np')
                loadave = self.findAttribute(node,'loadave')
                jobs = re.search('jobs =.*\n',node)
                if jobs is not None:
                    jobs = len(jobs.group().split(','))
                else:
                    jobs = 0
            else:
                state = 0
                ncpus = 1
                loadave = 0
                jobs = 0
                offline = 1
            self.nodeList.append( 
                    {'number'    : number,
                     'state'     : state,
                     'jobs'      : jobs,
                     'ncpus'     : ncpus,
                     'load'      : loadave / ncpus,
                     'isOffline' : 1* offline,
                     })

    def saveFile(self):
        sortedNodeList = sorted(self.nodeList,key=lambda k: k['number'])
        with open(self.fileloc,'w') as f:
            for i,node in enumerate(sortedNodeList):
                if node['state']==1:
                    f.write('{} {} {} {} {}\n'.format(
                        'Linux',
                        node['jobs'],
                        node['ncpus'],
                        node['load'],
                        node['isOffline'],
                        ))
                elif node['state']==2:
                    f.write('{} {}\n'.format('Windows',node['nUsers']))
                else:
                    f.write('offline\n')


cluster()
