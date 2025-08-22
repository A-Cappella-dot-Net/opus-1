Feature: Ecn User Manager - One Instance

Background: 
  Given there are 1 ecn user managers for ecn ecn1

Scenario: Baseline case
  - attempt to log in into ecn requires 4 conditions:
    (1) instance of ecn user manager is primary
    (2) market is open (we have a connection to the exchange)
    (3) ecn credentials are defined for the Madrigal user
    (4) Madrigal user is logged in
  - when Madrigal user logs out the ecn user is logged out from exhange

  Given ecn user managers are started
  | instance |
  |        0 |

  When ecn user manager receives ft member notification
	| instance | action     |
	|        0 | ACTIVATE   |
  Then ecn user manager instance 0 sends no request to ecn

	When ecn user manager receives market status
	| ecn  | status | gwt           |
	| ecn1 | OPEN   | ORDER_MANAGER |
  Then ecn user manager instance 0 sends no request to ecn

  When ecn user manager receives user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | login  | On     | On        |      |
  Then ecn user manager instance 0 sends no request to ecn

  When ecn user manager receives ecn credentials
	| uid  | ecn  | ecnUid  | ecnPwd  |
	| uid1 | ecn1 | ecnUid1 | ecnPwd1 |
  Then ecn user manager instance 0 sends request to ecn
  | op    | uid     | pwd     |
  | login | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login |      |

  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status    | text |
  | ecnUid1 | LOGGED_IN |      |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | status | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login | On     |      |

  When ecn user manager receives user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | logout | Off    | Off       |      |
  Then ecn user manager instance 0 sends request to ecn
  | op     | uid     | pwd     |
  | logout | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | logout |      |

  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status        | text |
  | ecnUid1 | NOT_LOGGED_IN |      |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | status | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | logout | Off    |      |


Scenario: On market CLOSE no logout request is sent to exchange but internal login state is Off

  Given ecn user managers are started
  | instance |
  |        0 |

  When ecn user manager receives ft member notification
	| instance | action     |
	|        0 | ACTIVATE   |
	And ecn user manager receives market status
	| ecn  | status | gwt           |
	| ecn1 | OPEN   | ORDER_MANAGER |
  And ecn user manager receives ecn credentials
	| uid  | ecn  | ecnUid  | ecnPwd  |
	| uid1 | ecn1 | ecnUid1 | ecnPwd1 |
  And ecn user manager receives user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | login  | On     | On        |      |
  Then ecn user manager instance 0 sends request to ecn
  | op    | uid     | pwd     |
  | login | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login |      |

  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status    | text |
  | ecnUid1 | LOGGED_IN |      |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | status | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login | On     |      |

	When ecn user manager receives market status
	| ecn  | status | gwt           |
	| ecn1 | CLOSED | ORDER_MANAGER |
  Then ecn user manager instance 0 sends no request to ecn
  And ecn user manager instance 0 publishes no ecn user request
  And ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | status | text          |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | logout | Off    | Market CLOSED |


Scenario: Corner case: incorrect ecn credentials

  Given ecn user managers are started
  | instance |
  |        0 |

  # the ecn credentials are wrong to start with
  When ecn user manager receives ft member notification
	| instance | action     |
	|        0 | ACTIVATE   |
	And ecn user manager receives market status
	| ecn  | status | gwt           |
	| ecn1 | OPEN   | ORDER_MANAGER |
  And ecn user manager receives ecn credentials
	| uid  | ecn  | ecnUid  | ecnPwd  |
	| uid1 | ecn1 | ecnUid1 | ecnPwd1 |
  And ecn user manager receives user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | login  | On     | On        |      |
  Then ecn user manager instance 0 sends request to ecn
  | op    | uid     | pwd     |
  | login | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login |      |

  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status        | text                |
  | ecnUid1 | NOT_LOGGED_IN | Invalid credentials |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | status | text                |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login | Off    | Invalid credentials |

  # the ecn credentials are corrected and received on the live subscription
  When ecn user manager receives ecn credentials
	| uid  | ecn  | ecnUid  | ecnPwd  |
	| uid1 | ecn1 | ecnUid1 | ecnPwd2 |
  Then ecn user manager instance 0 sends request to ecn
  | op    | uid     | pwd     |
  | login | ecnUid1 | ecnPwd2 |
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd2 | login |      |

  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status    | text |
  | ecnUid1 | LOGGED_IN |      |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | status | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd2 | login | On     |      |

  # the ecn credentials are changed again and received on the live subscription
  When ecn user manager receives ecn credentials
	| uid  | ecn  | ecnUid  | ecnPwd  |
	| uid1 | ecn1 | ecnUid1 | ecnPwd3 |
	# the ecn user manager sends logout using the old credentials (correct ones)
  Then ecn user manager instance 0 sends request to ecn
  | op     | uid     | pwd     |
  | logout | ecnUid1 | ecnPwd2 |
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd2 | logout |      |

  # when the exchange accepts the logout request
  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status        | text |
  | ecnUid1 | NOT_LOGGED_IN |      |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | status | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd2 | logout | Off    |      |
  # the ecn user manager sends another request using the new (but incorrect credentials)
  And ecn user manager instance 0 sends request to ecn
  | op    | uid     | pwd     |
  | login | ecnUid1 | ecnPwd3 |
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd3 | login  |      |

  # and the exchange rejects the new request
  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status        | text                |
  | ecnUid1 | NOT_LOGGED_IN | Invalid credentials |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | status | text                |
  | uid1 | ecn1 | ecnUid1 | ecnPwd3 | login | Off    | Invalid credentials |

  # the ecn credentials are changed again and received on the live subscription
  When ecn user manager receives ecn credentials
	| uid  | ecn  | ecnUid  | ecnPwd  |
	| uid1 | ecn1 | ecnUid3 | ecnPwd3 |
	# the ecn user manager sends login using the new credentials
  Then ecn user manager instance 0 sends request to ecn
  | op     | uid     | pwd     |
  | login  | ecnUid3 | ecnPwd3 |
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | text |
  | uid1 | ecn1 | ecnUid3 | ecnPwd3 | login  |      |

  # and the exchange accepts the new request
  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status    | text |
  | ecnUid3 | LOGGED_IN |      |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | status | text |
  | uid1 | ecn1 | ecnUid3 | ecnPwd3 | login | On     |      |

Scenario: Corner case: uid is associated with another ecn uid properly credentialed

  Given ecn user managers are started
  | instance |
  |        0 |

  # the ecn credentials are wrong to start with
  When ecn user manager receives ft member notification
	| instance | action     |
	|        0 | ACTIVATE   |
	And ecn user manager receives market status
	| ecn  | status | gwt           |
	| ecn1 | OPEN   | ORDER_MANAGER |
  And ecn user manager receives ecn credentials
	| uid  | ecn  | ecnUid  | ecnPwd  |
	| uid1 | ecn1 | ecnUid1 | ecnPwd1 |
  And ecn user manager receives user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | login  | On     | On        |      |
  Then ecn user manager instance 0 sends request to ecn
  | op    | uid     | pwd     |
  | login | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login |      |

  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status    | text |
  | ecnUid1 | LOGGED_IN |      |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | status | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login | On     |      |

  # the ecn credentials are corrected and received on the live subscription
  When ecn user manager receives ecn credentials
	| uid  | ecn  | ecnUid  | ecnPwd  |
	| uid1 | ecn1 | ecnUid2 | ecnPwd2 |
  Then ecn user manager instance 0 sends request to ecn
  | op     | uid     | pwd     |
  | logout | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | logout |      |

  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status        | text |
  | ecnUid1 | NOT_LOGGED_IN |      |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | status | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | logout | Off    |      |
  And ecn user manager instance 0 sends request to ecn
  | op     | uid     | pwd     |
  | login  | ecnUid2 | ecnPwd2 |
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | text |
  | uid1 | ecn1 | ecnUid2 | ecnPwd2 | login  |      |

  # and the exchange accepts the new request
  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status    | text |
  | ecnUid2 | LOGGED_IN |      |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | status | text |
  | uid1 | ecn1 | ecnUid2 | ecnPwd2 | login | On     |      |


Scenario: Corner case: before receiving a reply from exchange the market status changes to CLOSED

  When ecn user managers are started
  | instance |
  |        0 |

  When ecn user manager receives ecn credentials
	| uid  | ecn  | ecnUid  | ecnPwd  |
	| uid1 | ecn1 | ecnUid1 | ecnPwd1 |
  And ecn user manager receives ft member notification
	| instance | action     |
	|        0 | ACTIVATE   |
  And ecn user manager receives user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | login  | On     | On        |      |
  Then ecn user manager instance 0 sends no request to ecn

	When ecn user manager receives market status
	| ecn  | status | gwt           |
	| ecn1 | OPEN   | ORDER_MANAGER |
  Then ecn user manager instance 0 sends request to ecn
  | op    | uid     | pwd     |
  | login | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login |      |

	When ecn user manager receives market status
	| ecn  | status | gwt           |
	| ecn1 | CLOSED | ORDER_MANAGER |
  Then ecn user manager instance 0 sends no request to ecn
  And ecn user manager instance 0 publishes no ecn user request

  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | status | text          |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | logout | Off    | Market CLOSED |

	When ecn user manager receives market status
	| ecn  | status | gwt           |
	| ecn1 | OPEN   | ORDER_MANAGER |
  Then ecn user manager instance 0 sends request to ecn
  | op    | uid     | pwd     |
  | login | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login |      |

  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status    | text |
  | ecnUid1 | LOGGED_IN |      |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | status | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login  | On     |      |

