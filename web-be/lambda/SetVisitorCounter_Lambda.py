import json, os, boto3, hashlib, datetime
from boto3.dynamodb.conditions import Key

def lambda_handler(event, context):
    # Printing these out for logging
    print('Log: ## EVENT')
    print(f"Log: {event}")
    print('Log: ## Context')
    print(f"Log: {context}")
    print('Log: Changing the py file did result in TF updating the code in the Lambda FXN.')

    # Define global vars
    TABLENAME = os.environ['ddbtablename']
    REGION = os.environ['regionname']
    PK = os.environ['ddbpk']
    VISITORCOUNTER_PKID = os.environ['ddbvisitorcounterpkid']
    VISITORCOUNTER_COUNTATTR = os.environ['ddbcountattr']
    UNIQUE_TIMESTAMPATTR = os.environ['ddbdateattr']
    # The number of seconds between visits by the same IP where we reset the unique counter
    UNIQUE_TIMEDIFF = float(os.environ['ddbuniquediff']) * 24 * 60 * 60

    print('Log: ## ENVIRONMENT VARIABLES')
    print(f"ddbtablename={os.environ['ddbtablename']}")
    print(f"regionname={os.environ['regionname']}")
    print(f"ddbpk={os.environ['ddbpk']}")
    print(f"ddbvisitorcounterpkid={os.environ['ddbvisitorcounterpkid']}")
    print(f"ddbcountattr={os.environ['ddbcountattr']}")
    
    # Value that dictates whether we run the command to increment the site counter
    INCREMENTCOUNTER = True
    # current time in a timestamp format that's good for math (its a float)
    CURRENTTIME = (datetime.datetime.utcnow() - datetime.datetime(1970,1,1)).total_seconds()
    CURRENTTIME = str(CURRENTTIME)

    DYNAMODB = boto3.resource('dynamodb',region_name=REGION)
    TABLE = DYNAMODB.Table(TABLENAME)
   
   
    INCREMENTCOUNTER = CheckUniqueness(event, CURRENTTIME, PK, UNIQUE_TIMEDIFF, TABLE, UNIQUE_TIMESTAMPATTR)
    STATUS, CURRENTCOUNT, UPDATEDCOUNT = HandleCounter(PK, VISITORCOUNTER_PKID, INCREMENTCOUNTER, TABLE, VISITORCOUNTER_COUNTATTR)
    BODY = f'"Status":"{STATUS}","Before":"{CURRENTCOUNT}","After":"{UPDATEDCOUNT}"'
    BODY = '{' + BODY + '}'

    return {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": { 
            "Access-Control-Allow-Origin": '*'
            
        },
        "body": BODY
    }

def CheckUniqueness(request, currenttime, partitionkey, uniquediff, ddbtable, timestamptattr):
    # validate whether sourceIp is in the web request or not
    if 'requestContext' in request and 'identity' in request['requestContext'] and 'sourceIp' in request['requestContext']['identity']:
        # get the SourceIP from the web request
        sourceIP = request['requestContext']['identity']['sourceIp']
        print('Log: ## IP')
        print(f"Log: {sourceIP}")

        # hash the IP and work with the hash for privacy's sake
        my_hash = hashlib.sha256(sourceIP.encode('utf-8')).hexdigest()
        print('Log: ## IP HASH')
        print(f"Log: {my_hash}")
        print(f"Log: type of my_hash is {type(my_hash)}")

        # check whether the IPhash is already present in the table
        response = ddbtable.get_item(Key={partitionkey: my_hash})

        # this indicates the IP hash was found in the DDB table
        if 'Item' in response:
            print("Log: Found a record of the hash already in the ddb table. Checking the visitdate")
            
            # check that there is a date time attr in the item
            if timestamptattr in response['Item']:
                print(f"Log: Found the {timestamptattr} attribute in the item.")
                usertimestamp = float(response['Item'][timestamptattr])
                temptimediff = float(currenttime) - usertimestamp
                if (temptimediff > uniquediff):
                    print(f"Log: The difference between the current time {currenttime} and user last visit time stamp {usertimestamp} is GREATER than the required interval {uniquediff}. Updating the timestampt to current time and returning true to indicate the count should be incremented.")
                    
                    # since this is a 'unique' visit, update the timestamp for this IPhash 
                    response = ddbtable.update_item(
                        Key={partitionkey:my_hash},
                        UpdateExpression= f'set {timestamptattr} = :val',
                        ExpressionAttributeValues={
                            ':val': f'{currenttime}'
                        },
                        ReturnValues="UPDATED_NEW"
                    )
                    print(f"Log: The result of the ddb.updatetable-set for the timestamp is {response}")
                    #@# validate the update worked - make sure response is what is expected

                    #since this is a unique visit we will update the counter
                    return True 
                
                else:
                    print(f"Log: The difference between the current time {currenttime} and user last visit time stamp {usertimestamp} is LESS than the required interval {uniquediff}. Returning false so the visitor count is not incremented.")
                    return False
            else: 
                print(f"Log: There is no datetime attribute in the DDB item with pk={partitionkey}{my_hash} in the table. Now updating the item with the datetime attribute. ")
                # since this is a 'unique' visit, update the timestamp for this IPhash 
                response = ddbtable.update_item(
                    Key={partitionkey:my_hash},
                    UpdateExpression= f'add {timestamptattr} = :val',
                    ExpressionAttributeValues={
                        ':val': f'{currenttime}'
                    },
                    ReturnValues="UPDATED_NEW"
                )
                print(f"Log: The result of the ddb.updatetable-add for the timestamp is {response}")
                #@# validate the update worked - make sure response is what is expected

                # There was no date time attribute, but there was an IP hash. For now we will return true to have site counter incremented
                print("Log: There was no datetime attribute, but there was an IP hash. For now we will return true to have site counter incremented")
                return True
        else:
            print(f"Log: There is no record of {my_hash} in the table. This is a unique visitor. Now creating a new item.")
            print(f"Log: Since this is a unique visitor we are attempting to write {my_hash} to DDB table.")
            # Even if the Hash somehow already was in the table, the Put_item would overwrite it, which is fine for our needs
            response = ddbtable.put_item(Item={partitionkey:my_hash,timestamptattr:currenttime})
            print(f"Log: response of Put_item call is: {response}")
            # since this is a unique visitor, return true
            return True

    else: 
        #@# Consider what to do in this circumstance
        print('Log: SourceIP is not present in the request. We will go ahead and consider this a unique visit for now.')
        return True

    
def HandleCounter(partitionkey, visitorcounterkey, increment, ddbtable, countattr):
    response = ddbtable.get_item(Key={partitionkey:visitorcounterkey})

    if 'Item' in response:
        print(f"Log: The Get_Item call for PKID={visitorcounterkey} returned a valid item.")
        if countattr in response['Item']:
            print(f"Log: The Item given by PKID={visitorcounterkey} has the {countattr} in it.")
            currentval = response['Item'][countattr]
            if increment:
                print("Log: Since the INCREMENTCOUNTER var is true, we will increment the site counter.")
                newval = int(currentval) + 1
                response = ddbtable.update_item(
                    Key={partitionkey:visitorcounterkey},
                    UpdateExpression= f'set {countattr} = :val',
                    ExpressionAttributeValues={
                        ':val': f'{newval}'
                    },
                    ReturnValues="UPDATED_NEW"
                )
                print(f"Log: The result of the ddb.updateitem-set for the counter attribute is {response}")
                #@# validate the update worked - make sure response is what is expected
                return "INCREMENT", currentval, newval
            else:
                print("Log: Since the INCREMENTCOUNTER var is false, we will not increment the site counter.")
                return "NO-INCREMENT", currentval, currentval
        else: 
            print(f"Log: The Item given by PKID={visitorcounterkey} does not have the {countattr} in it. Adding it with site counter = 1.")
            #@# update the item by adding the countattr with value=1.
            response = ddbtable.update_item(
                Key={partitionkey:visitorcounterkey},
                UpdateExpression= f'add {countattr} = :val',
                ExpressionAttributeValues={
                    ':val': 1
                },
                ReturnValues="UPDATED_NEW"
            )
            print(f"Log: The result of the ddb.updateitem-add for the counter attribute is {response}")
            #@# validate the update worked - make sure response is what is expected
            return "INCREMENT", 1, 1
    else:
        print(f"Log: The Item given by PKID={visitorcounterkey} does not exist. Creating it with site counter = 1.")
        response = ddbtable.put_item(Item={partitionkey:visitorcounterkey,countattr:1})
        #@# validate the put worked
        print(f"Log: response of Put_item call for SiteCounter is: {response}")
        return "INCREMENT", 1, 1


   