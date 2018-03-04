#!/usr/bin/python

import mysql.connector

# create an account with minimal priviledges.
# For "SHOW SLAVE STATUS", only the REPLICATION CLIENT privilege is needed.
USER = "USER"
PASSWORD = "PASSWORD"

def get_slave_status():
    try:
        conn = mysql.connector.connect( host="localhost", user=USER, password=PASSWORD)
        cursor = conn.cursor()
        cursor.execute("SHOW SLAVE STATUS")
        sequence = cursor.column_names
        status = dict(zip(cursor.column_names, cursor.fetchone()))

    except:
        print "Error while retrieving status. Check if database is running or the credentials are correct."
        return None

    return status


def set_weight(slave_status):
    
    lag = slave_status['Seconds_Behind_Master']

    if lag == None:
        return "down"
    elif lag < 10:
        return "up 100%"
    elif lag >= 10 and lag < 60:
        return "up 50%"
    else:
        return "up 5%"



if __name__ == "__main__":

    status = get_slave_status()
    print set_weight(status)
