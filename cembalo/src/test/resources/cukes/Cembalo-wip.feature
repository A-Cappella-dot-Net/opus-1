Feature: Exchange - Work in progress Scenarios
  This is normally an empty feature file used to develop new Scenarios and test
  them before adding them to the proper feature file. This way we are running one
  scenario at a time, the one that is actively being developed.

#	Then no market data snapshot for 912828Q45 is sent
#	And no execution reports are sent

  Background:
    Given the set of available instruments is
      | secId     | minQty | minQtyIncrement | minPriceIncrement | ordering | maxLevels |
      | 912828Q45 | 1.0    | 1.0             | 0.0078125         | 1        | 20        |
    And all books are initialized in open matching state
    And exchange starts with no active orders

