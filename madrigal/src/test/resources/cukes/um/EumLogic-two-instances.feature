Feature: Ecn User Manager - Two Instances

Background: 
  Given there are 2 ecn user managers for ecn ecn1

Scenario: Two ecn user managers and failover

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

  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status    | text |
  | ecnUid1 | LOGGED_IN |      |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | status | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login | On     |      |

	# the second instance starts later
  When ecn user managers are started
  | instance |
  |        1 |
  # and initializes its state using snapSubscribe
  When ecn user manager instance 1 receives ecn user status
  | instance | uid  | ecn  | ecnUid  | ecnPwd  | op    | status | text |
  | 0        | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login | On     |      |
  And ecn user manager instance 1 receives ecn credentials
	| uid  | ecn  | ecnUid  | ecnPwd  |
	| uid1 | ecn1 | ecnUid1 | ecnPwd1 |
	And ecn user manager instance 1 receives market status
	| ecn  | status | gwt           |
	| ecn1 | OPEN   | ORDER_MANAGER |
  And ecn user manager receives ft member notification
	| instance | action     |
	|        1 | DEACTIVATE |
  And ecn user manager instance 1 receives user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | login  | On     | On        |      |
  Then ecn user manager instance 1 sends no request to ecn

  When ecn user managers are stopped
  | instance |
  |        0 |
  And ecn user manager receives ft member notification
	| instance | action     |
	|        1 | ACTIVATE   |
  Then ecn user manager instance 1 sends request to ecn
  | op     | uid     | pwd     |
  | logout | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 1 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op     |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | logout |

  When ecn user manager instance 1 receives response from ecn
  | ecnUid  | status        | text               |
  | ecnUid1 | NOT_LOGGED_IN | Already logged out |
  Then ecn user manager instance 1 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | status | text               |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | logout | Off    | Already logged out |

  When ecn user manager instance 1 sends request to ecn
  | op    | uid     | pwd     |
  | login | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 1 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login |      |

  When ecn user manager instance 1 receives response from ecn
  | ecnUid  | status    | text |
  | ecnUid1 | LOGGED_IN |      |
  Then ecn user manager instance 1 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | status | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login | On     |      |


Scenario: Corner case: while failing over madrigal user logs out

  When ecn user managers are started
  | instance |
  |        0 |
  |        1 |

  When ecn user manager receives ecn credentials
	| uid  | ecn  | ecnUid  | ecnPwd  |
	| uid1 | ecn1 | ecnUid1 | ecnPwd1 |
  And ecn user manager receives ft member notification
	| instance | action     |
	|        0 | ACTIVATE   |
	|        1 | DEACTIVATE |
  And ecn user manager receives user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | login  | On     | On        |      |
  Then ecn user manager instance 0 sends no request to ecn
  And ecn user manager instance 1 sends no request to ecn

	When ecn user manager receives market status
	| ecn  | status | gwt           |
	| ecn1 | OPEN   | ORDER_MANAGER |
  Then ecn user manager instance 0 sends request to ecn
  | op    | uid     | pwd     |
  | login | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 1 sends no request to ecn
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login |      |
  And ecn user manager instance 1 publishes no ecn user request

  When ecn user manager instance 0 receives response from ecn
  | ecnUid  | status    | text |
  | ecnUid1 | LOGGED_IN |      |
  Then ecn user manager instance 0 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | status | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login | On     |      |

  When ecn user managers are stopped
  | instance |
  |        0 |
  And ecn user manager receives ft member notification
	| instance | action     |
	|        1 | ACTIVATE   |
  Then ecn user manager instance 1 sends request to ecn
  | op     | uid     | pwd     |
  | logout | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 1 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op     |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | logout |

  When ecn user manager receives user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | logout | Off    | Off       |      |
  Then ecn user manager instance 1 sends no request to ecn

  When ecn user manager instance 1 receives response from ecn
  | ecnUid  | status        | text               |
  | ecnUid1 | NOT_LOGGED_IN | Already logged out |
  Then ecn user manager instance 1 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | status | text               |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | logout | Off    | Already logged out |
  And ecn user manager instance 1 sends no request to ecn


Scenario: Corner case: before receiving a reply from exchange the ecn user manager fails over

  When ecn user managers are started
  | instance |
  |        0 |
  |        1 |

  When ecn user manager receives ecn credentials
	| uid  | ecn  | ecnUid  | ecnPwd  |
	| uid1 | ecn1 | ecnUid1 | ecnPwd1 |
  And ecn user manager receives ft member notification
	| instance | action     |
	|        0 | ACTIVATE   |
	|        1 | DEACTIVATE |
  And ecn user manager receives user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | login  | On     | On        |      |
  Then ecn user manager instance 0 sends no request to ecn
  And ecn user manager instance 1 sends no request to ecn

	When ecn user manager receives market status
	| ecn  | status | gwt           |
	| ecn1 | OPEN   | ORDER_MANAGER |
  Then ecn user manager instance 0 sends request to ecn
  | op    | uid     | pwd     |
  | login | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 1 sends no request to ecn
  And ecn user manager instance 0 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op    | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login |      |
  And ecn user manager instance 1 publishes no ecn user request

  When ecn user managers are stopped
  | instance |
  |        0 |
  And ecn user manager receives ft member notification
	| instance | action     |
	|        1 | ACTIVATE   |
  Then ecn user manager instance 1 sends request to ecn
  | op     | uid     | pwd     |
  | login  | ecnUid1 | ecnPwd1 |
  And ecn user manager instance 1 publishes ecn user request
  | uid  | ecn  | ecnUid  | ecnPwd  | op     |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login  |

  When ecn user manager instance 1 receives response from ecn
  | ecnUid  | status    | text |
  | ecnUid1 | LOGGED_IN |      |
  Then ecn user manager instance 1 publishes ecn user status
  | uid  | ecn  | ecnUid  | ecnPwd  | op     | status | text |
  | uid1 | ecn1 | ecnUid1 | ecnPwd1 | login  | On     |      |


