####################################################################
# Usage: python getOptions.py	
# 										
# Script that takes an options file and creates a script file 	
# collectData that contains  commands to run the TDT factor	 
# scripts. Assumes an options file in the same directory. 
#		
# created by Judith Degen -- 06/20/09	
# last modified -- 08/30/09
####################################################################

import sys 

infile=open(sys.argv[2]+"/options")
outfile=open(sys.argv[2]+"/collectData","w")
oplines=[]
commands=dict(data=0,results=0,corpus=0,init=0,add=0)
bash=sys.argv[1]
corpus=str(sys.argv[3])
fileending=".t2o"

def out(towrite):
# writes to collectData
	outfile.write(towrite)
	
def flatten(x):
# flattens lists
    result = []
    for el in x:
        #if isinstance(el, (list, tuple)):
        if hasattr(el, "__iter__") and not isinstance(el, basestring):
            result.extend(flatten(el))
        else:
            result.append(el)
    return result
    	
def getVariable(v, corpus):
# get variable information and output  commands to collectData
#if no file name given, defaults to variable column name
	if len(v) < 2:
		raise Exception("missing argument(s)")
	if v[0] == "StringVar":
		if len(v) == 3:
			out("	addStringVar.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[2]+fileending))
		elif len(v) == 2:
			out("	 addStringVar.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[1]+fileending))	
	elif v[0] == "NodeVar":
		if len(v) == 3:
			out("	addNodeVar.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[2]+fileending))
		elif len(v) == 2:
			out("	addNodeVar.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[1]+fileending))
	elif v[0] == "ParseVar":
		if len(v) == 3:
			out("	addParseVar.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[2]+fileending))
		elif len(v) == 2:
			out("	addParseVar.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[1]+fileending))
	elif v[0] == "LengthVar":
		if len(v) == 3:
			out("	 addLengthVar.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[2]+fileending))
		elif len(v) == 2:
			out("	 addLengthVar.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[1]+fileending))	
	elif v[0] == "NiteIDVar":
                if len(v) == 3:
                        out("   addNiteID.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[2]+fileending))
                elif len(v) == 2:
                        out("   addNiteID.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[1]+fileending))		
	elif v[0] == "CategoricalVar":
		argus=[]
		cats=v[2].split(",")
		for c in cats:
			argus.append(c.split(":")[0])
			argus.append("$Pdata/"+c.split(":")[1]+fileending)
		out("	 addCategoricalVar.pl -oc %s -f %s %s\n"%(corpus,v[1]," ".join(argus)))
	elif v[0] == "CountVar":
		if len(v) == 3:
			out("	 addCountVar.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[2]+fileending))
		elif len(v) == 2:			
			out("	 addCountVar.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[1]+fileending))
	elif v[0] == "LemmaVar":
		if len(v) == 3:
			out("	 addLemma.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[2]+fileending))	
		elif len(v) == 2:			
			out("	 addLemma.pl -roc %s -f %s=$Pdata/%s\n"%(corpus,v[1],v[1]+fileending))	
	elif v[0] == "Phonology":
		factors = ",".join(v[1:])
		out("	 addPhonology.pl -roc %s -f %s\n"%(corpus,factors))
	elif v[0] == "InfoDensity":
		out("	 addInformationDensity.pl -roc %s -f %s 3\n"%(corpus,v[1]+fileending))
	elif v[0] == "CondProb":
		out("	 addConditionalProbability.pl -c %s -f %s\n"%(corpus,v[1]+fileending))	
	elif v[0] == "Frequency":
		out("	addUnigram.pl -c %s -f %s\n"%(corpus,v[1]+fileending))	
	elif v[0] == "SocialVar":
		# make sure social information is available 
		if corpus in ["swbd"]:
			out("	addConversationInfo.pl -roc %s -f %s\n"%(corpus,v[1]+fileending))
		else:
			print "social/conversation meta information is not available for this corpus"
	else:
		raise Exception("variable type not recognized: %s"%v[0])		

# extra definitions over    	
##################################################################################
# script starts
    	
# throw out junk
lines=[l.rstrip() for l in infile.readlines()]
for l in lines:
	if len(l) > 3:
		if not l.startswith("#"):
			if not l.startswith("*"):
				oplines.append(l)
			

blines=[l.split("=") for l in oplines]
oplines=[]
for b in blines:
	if type(b)==type(""):
		oplines.append(b.split())
	else:
		oplines.append(flatten([a.split() for a in b]))

lines=[l for l in oplines if l[0] in commands.keys()]
for l in lines:
	commands[l[0]]+=1

if commands['data']<1:
	raise Exception("specify where the .sn files are using the 'data' command")
elif commands['data']>1:
	raise Exception("too many 'data' commands - specify only once")
elif commands['data']>1:
	raise Exception("too many 'corpus' commands - specify only once")	
elif commands['results']<1:
	raise Exception("specify where to create the database using the 'results' command")
elif commands['results']>1:
	raise Exception("too many 'results' commands - specify only once")
elif commands['init']<1:
	raise Exception("no file to initialize database from - specify using 'init' command")
elif commands['init']>1:
	raise Exception("too many 'init' commands - specify only once")		
	

# collect options from lines

variables=[]

for l in lines: #TODO: make sure to handle empty or too many data arguments
	if l[0] == "data":
		data = l[1]+"/"+corpus+"/"
	elif l[0] == "results":
		results = l[1]
	elif l[0] == "init":
		idfile = l[1]
	elif l[0] == "add":
		variables.append(l[1:])

# write to collectData

if(bash=="/bin/bash"):
	out("#!/bin/bash\n\n")
	out("cd %s\n"%results)
	out("export Pdata=%s\n"%data)
	out("export Presults=%s\n"%results)
else: #default to csh
	out("#!/bin/csh -f\n\n")
	out("cd %s\n"%results)
	out("setenv Pdata %s\n"%data)
	out("setenv Presults %s\n"%results)
	
out("echo Creating new corpus file %s.tab\n"%corpus)
out("	initDatabase.pl -roc %s --files $Pdata/%s\n\n"%(corpus,idfile))
out("echo Beginning data extraction...\n")
out("echo\n")
for v in variables:
	if v[0] == "-acc":
		getVariable(v[1:],corpus)
		if len(v) == 4:
			out("	 accumulateVarValues.pl -oc %s -f %s\n"%(corpus,v[3]))
		elif len(v) == 3:
			out("	accumulateVarValues.pl -oc %s -f %s\n"%(corpus,v[2]))
	else:
		getVariable(v,corpus)
	
out("\n")
#out("echo Moving new output file to $Presults/%s.tab\n"%corpus)
#out("	mv -f %s.tab $Presults/%s.tab\n"%(corpus,corpus))
out("cd $TDTlite")


infile.close()
outfile.close()
