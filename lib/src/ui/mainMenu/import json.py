import json

data = []
inputting = True

while inputting:
    nameInput = input("")
    if nameInput == 'q':
        inputting = False
    else:
        splitName = nameInput.split()
        newName = {
            'id': int(splitName[0]),
            'name': splitName[1],
            'gender': splitName[2],
            'parent': int(splitName[3]),
            'children': [int(x) for x in splitName[4:]]
        }
        data.append(newName)
        print(data)

with open('familylist.json', 'w') as outfile:
    json.dump(data, outfile)