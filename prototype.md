prototype to use erlhive as a message server for card game such as contract bridge
# Introduction #

A message server is a common place that maintains queues for sender to place message and receiver to retrieve message.


# General Ideas #

Contract bridge server is a good example to make use a simple message server. Traditional implementation such as floater, blue chip bridge requires 4-5 direct TCP connections between server and player, this puts a limitation on internet users that behind firewall to play with each other. An internet hosted server can be used as a transport server to maintain connections to all clients.

In our simple case, no real time communication is needed, a session based communication model is good enough. Thus server can utilize any web based architecture to implement the message server.

In general, the message server maintains a list of queues to store messages to or from each client. Each queue can be differentiated by client id based harsh. Client follows a server determined convention to send or receive its message. For instance,
A message to a server may look like
```
From: client-public-name
ID: client-server-association-harsh
To: a list of other clients' public name 
Content: actual messages
```
The way it works should be similar to how email works.

In the case of contract bridge server. A client registers to the server and claims to be table manager. The information about the existence of table manager is published. Other clients then can register to the server and send table manager messages to request join the table and once accepted by the manager to choose seat. Table manager will later on send cards to each player and coordinate the progress of auction, playing and scoring.

The message server implementation could be a good start for getting familiar with erlhive. Of course due to its openness and simplicity any client can connect to the server and client can form its own server. With small modification client can use other transport as well, such as email, IM etc.

The TCP connection between client and server does not need to be maintained all the time. A client pull model is better suited to a message based communication. But it needs to pull more frequently if other player is also human.

references:
[oldlady](http://www.kuliniewicz.org/blog/archives/category/coding/old-lady/)
[deal evaluation](http://bridge.thomasoandrews.com/deal/advanced.html)
[computer bridge](http://www.ny-bridge.com/allevy/computerbridge/)
[pybridge](https://launchpad.net/pybridge)
[floater](http://floaterbridge.cvs.sourceforge.net)
[freebridge](http://freebridge.sourceforge.net/)
[dds10 solver](http://www.aleax.it/Bridge/)