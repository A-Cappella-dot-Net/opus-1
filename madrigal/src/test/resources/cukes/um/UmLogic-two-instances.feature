Feature: User Manager - Two Instances

Background: 
  - two user-manager services not necessarily starting at the same time
  Given there are 2 user manager services

Scenario: Baseline case: login, failover, logout
  - one user-manager becomes active the other passive
  - both user-manager servers receive credentials info
  - initially no users are logged in
  - a user logs in with the correct credentials
  - the user manager sevice fails over
  - the user logs out with the correct credentials

  Given user manager services are started
  | instance |
  |        0 |
  |        1 |

  When user manager service receives ft member notification
	| instance | action     |
	|        0 | ACTIVATE   |
	|        1 | DEACTIVATE |
  And user manager service receives credentials
	| instance | uid  | pwd  |
	|       -1 | uid1 | pwd1 |
  And user manager service receives a user request
  | uid  | clId  | op    | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId1 | login | pwd1 | false            | false       |
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op    | status | reqStatus | text |
	| uid1 | clId1 | login | On     | On        |      |
  And user manager service instance 1 publishes no user status

  # primary instance is stopped
  When user manager services are stopped
  | instance |
  |        0 |
  # instance 1 is activated by the FT mechanism
  And user manager service receives ft member notification
	| instance | action     |
	|        1 | ACTIVATE   |
  And user manager service instance 1 publishes no user status

	# the user is still logged in and tries to log out
  When user manager service receives a user request
  | uid  | clId  | op     | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId1 | logout | pwd1 | false            | false       |
  Then user manager service instance 1 publishes user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | logout | Off    | Off       |      |


Scenario: Delayed start scenario: first service starts, login, second service starts, failover, logout
  - one user manager instance starts, becomes active, and receives credentials
  - user logs in into Madrigal using this instance
  - the second user manager instance starts, is instructed to stand by
  - the second user manager receives credentials and current user statuses via snapSubscribe
  - the first user manager instance is stopped and the second instance is instructed to activate
  - user is able to successfully log out using the second instance

  Given user manager services are started
  | instance |
  |        0 |

  When user manager service receives ft member notification
	| instance | action     |
	|        0 | ACTIVATE   |
  And user manager service receives credentials
	| instance | uid  | pwd  |
	|       -1 | uid1 | pwd1 |
  And user manager service receives a user request
  | uid  | clId  | op    | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId1 | login | pwd1 | false            | false       |
  | uid1 | clId2 | login | pwd1 | false            | false       |
  | uid1 | clId3 | login | pwd1 | false            | false       |
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op    | status | reqStatus | text                   |
	| uid1 | clId1 | login | On     | On        |                        |
	| uid1 | clId2 | login | On     | On        | uid1 already logged in |
	| uid1 | clId3 | login | On     | On        | uid1 already logged in |

  When user manager services are started
  | instance |
  |        1 |
  And user manager service receives ft member notification
	| instance | action     |
	|        1 | DEACTIVATE |
  And user manager service receives credentials
	| instance | uid  | pwd  |
	|        1 | uid1 | pwd1 |
	# on starup instance 1 perform a snapSubscribe for user.status
  And user manager service instance 1 receives user status
	| uid  | clId  | op    | status | reqStatus | text                   |
	| uid1 | clId1 | login | On     | On        |                        |
	| uid1 | clId2 | login | On     | On        | uid1 already logged in |
	| uid1 | clId3 | login | On     | On        | uid1 already logged in |


  # primary instance is stopped
  When user manager services are stopped
  | instance |
  |        0 |
  # instance 1 is activated by the FT mechanism
  And user manager service receives ft member notification
	| instance | action     |
	|        1 | ACTIVATE   |
	# the user is still logged in into clId1 and tries to log out
  And user manager service receives a user request
  | uid  | clId  | op     | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId1 | logout | pwd1 | false            | false       |
  Then user manager service instance 1 publishes user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | logout | On     | Off       |      |

	# the user is still logged in into clId2 and tries to log out
  When user manager service receives a user request
  | uid  | clId  | op     | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId2 | logout | pwd1 | false            | false       |
  Then user manager service instance 1 publishes user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId2 | logout | On     | Off       |      |

	# the user is still logged in into clId3 and tries to log out
  And user manager service receives a user request
  | uid  | clId  | op     | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId3 | logout | pwd1 | false            | false       |
  Then user manager service instance 1 publishes user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId3 | logout | Off    | Off       |      |

