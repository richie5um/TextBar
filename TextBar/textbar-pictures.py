#!/usr/bin/env python
#coding=utf-8
import sys
import os
import tempfile

picturesPath = "~/Pictures"
if 1 < len(sys.argv):
    picturesPath = sys.argv[1]

expandedPath = os.path.expanduser(picturesPath)
imageStyle = "style='display: block; max-width:230px; max-height:95px; width: auto; height: auto;'"
tempPath = os.path.join(tempfile.gettempdir(), 'textbar')

# Ensure TextBar temp folder exists
try:
    os.makedirs(tempPath)
except OSError:
    pass

actionsPath = os.path.join(tempPath, 'picturesActions.py')
actionsFile = open(actionsPath, 'w')
actionsFile.truncate()
actionsFile.write('#!/usr/bin/env python\n#coding=utf-8\n')
actionsFile.write('import os\n')
actionsFile.write('actionIndex = int(os.getenv(\'TEXTBAR_INDEX\', 0))-1\n')
actionsFile.write('actions = []\n')

print "Pictures"
fileList = os.listdir(expandedPath)
for fileName in fileList:
    _, extension = os.path.splitext(fileName)

    imageExtensions = set(['jpg', 'jpeg', 'png', 'gif'])
    if (extension.lower()[1:] in imageExtensions):
        imagePath = os.path.join(expandedPath, fileName)
        tempImagePath = os.path.join(tempPath, fileName)
        if True != os.path.isfile(tempImagePath):
            os.system("sips -Z 100 '{0}' --out '{1}' &> /dev/null".format(imagePath, tempImagePath))
        print "<html><img {0} src=\"file://{1}\"></img><br/></html>".format(imageStyle, tempImagePath)
        actionsFile.write("actions.append(\'osascript -e \\\'set the clipboard to ( POSIX file \\\"{0}\\\" )\\\'\')\n".format(imagePath))

actionsFile.write('os.system(\'{0}\'.format(actions[actionIndex]))\n')
actionsFile.close()
os.system("chmod +x {0}".format(actionsPath))

textbarDir = ""
try:
    textbarDir = os.environ["TEXTBAR_DIR"]
except KeyError:
    pass

if 0 < len(textbarDir):
    # Ensure TextBar output folder exists
    try:
        os.makedirs(textbarDir)
    except OSError:
        textbarDir = ""
        pass

if 0 < len(textbarDir):
    actionsScriptPath = os.path.join(textbarDir, 'ACTIONSCRIPT')
    actionsScriptFile = open(actionsScriptPath, 'w')
    actionsScriptFile.truncate()
    actionsScriptFile.write(actionsPath)
    actionsScriptFile.close()
