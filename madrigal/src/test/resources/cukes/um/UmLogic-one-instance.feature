Feature: User Manager - One Instance

Background: 
  - one user-manager service
  Given there are 1 user manager services


Scenario: Corner case: Unknown user

  Given user manager services are started
  | instance |
  |        0 |

  When user manager service receives ft member notification
	| instance | action     |
	|        0 | ACTIVATE   |
  And user manager service receives a user request
  | uid  | clId  | op    | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId1 | login | pwd1 | false            | false       |
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op    | status | reqStatus | text              |
	| uid1 | clId1 | login | Off    | Off       | Unknown user uid1 |


Scenario: Corner case: Invalid credentials

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
  | uid1 | clId1 | login | pwd2 | false            | false       |
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op    | status | reqStatus | text                     |
	| uid1 | clId1 | login | Off    | Off       | Invalid credentials uid1 |


Scenario: Corner case: Already logged in

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
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op    | status | reqStatus | text |
	| uid1 | clId1 | login | On     | On        |      |

  # user logs in twice from the same client
  And user manager service receives a user request
  | uid  | clId  | op    | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId1 | login | pwd1 | false            | false       |
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op    | status | reqStatus | text                         |
	| uid1 | clId1 | login | On     | On        | uid1/clId1 already logged in |

  # user logs in twice from different clients
  When user manager service receives a user request
  | uid  | clId  | op    | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId2 | login | pwd1 | false            | false       |
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op    | status | reqStatus | text                   |
	| uid1 | clId2 | login | On     | On        | uid1 already logged in |

  # user logs in twice from different clients but rejectIfLoggedIn=true 
  When user manager service receives a user request
  | uid  | clId  | op    | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId4 | login | pwd1 | true             | false       |
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op    | status | reqStatus | text                   |
	| uid1 | clId4 | login | On     | Off       | uid1 already logged in |

  When user manager service receives a user request
  | uid  | clId  | op    | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId3 | login | pwd1 | false            | false       |
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op    | status | reqStatus | text                   |
	| uid1 | clId3 | login | On     | On        | uid1 already logged in |

  # forceLogout = true logs out all instances
  And user manager service receives a user request
  | uid  | clId  | op     | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId1 | logout | pwd1 | false            | true        |
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | logout | Off    | Off       |      |


Scenario: Corner case: Never logged in

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
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op    | status | reqStatus | text |
	| uid1 | clId1 | login | On     | On        |      |

  When user manager service receives a user request
  | uid  | clId  | op     | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId2 | logout | pwd1 | false            | false       |
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op     | status | reqStatus | text                       |
	| uid1 | clId2 | logout | On     | Off       | uid1/clId2 never logged in |


Scenario: Corner case: Already logged out

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
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op    | status | reqStatus | text |
	| uid1 | clId1 | login | On     | On        |      |

  When user manager service receives a user request
  | uid  | clId  | op     | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId1 | logout | pwd1 | false            | false       |
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | logout | Off    | Off       |      |

  When user manager service receives a user request
  | uid  | clId  | op     | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId1 | logout | pwd1 | false            | false       |
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op     | status | reqStatus | text                    |
	| uid1 | clId1 | logout | Off    | Off       | uid1 already logged out |


Scenario: Baseline case: login and logout

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
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op    | status | reqStatus | text |
	| uid1 | clId1 | login | On     | On        |      |

  When user manager service receives a user request
  | uid  | clId  | op     | pwd  | rejectIfLoggedIn | forceLogout |
  | uid1 | clId1 | logout | pwd1 | false            | false       |
  Then user manager service instance 0 publishes user status
	| uid  | clId  | op     | status | reqStatus | text |
	| uid1 | clId1 | logout | Off    | Off       |      |

