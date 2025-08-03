Feature: Cembalo - Size Amend with strictRwt

  Background:
    Given the server is set up with strictRwt
    And the set of available instruments is
      | secId     | minQty | minQtyIncrement | minPriceIncrement | ordering | maxLevels |
      | 912828Q45 | 1.0    | 1.0             | 0.0078125         | 1        | 20        |
    And all books are initialized in open matching state
    And exchange starts with no active orders

  Scenario: Replace to more than filled
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 9.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 9.0 and shown 9.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 0.0     | NaN    | 9.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id2 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 4.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 4.0 and shown 4.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 5.0     | 102.0  | 4.0       | 5.0    | 102.0 |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 | New      | New             | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 | Trade    | PartiallyFilled | 5.0     | 102.0  | 4.0       | 5.0    | 102.0 |      |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 | Trade    | Filled          | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     1 | 00000-1 | 7.0      | 7.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 2.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 2.0 and shown 2.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | Buy    | 7.0      | 7.0     | 0.0     | NaN    | 2.0       | 5.0    | 102.0 |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | Buy    | 7.0      | 7.0     | 102.0 | Replaced | Replaced  | 0.0     | NaN    | 2.0       | 5.0    | 102.0 |      |


  Scenario: Replace to exactly filled
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 9.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 9.0 and shown 9.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 0.0     | NaN    | 9.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id2 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 4.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 4.0 and shown 4.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 5.0     | 102.0  | 4.0       | 5.0    | 102.0 |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 | New      | New             | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 | Trade    | PartiallyFilled | 5.0     | 102.0  | 4.0       | 5.0    | 102.0 |      |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 | Trade    | Filled          | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     1 | 00000-1 | 5.0      | 5.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 0.0       | NaN      | NaN      | 0.0       |
    And there are no continuous orders for instrument 912828Q45 and side Buy at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | Buy    | 5.0      | 5.0     | 102.0 | Replaced | Filled    | 0.0     | NaN    | 0.0       | 5.0    | 102.0 |      |

  Scenario: Replace to less than filled
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 9.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 9.0 and shown 9.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 0.0     | NaN    | 9.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id2 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 4.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 4.0 and shown 4.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 5.0     | 102.0  | 4.0       | 5.0    | 102.0 |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 | New      | New             | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 | Trade    | PartiallyFilled | 5.0     | 102.0  | 4.0       | 5.0    | 102.0 |      |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 | Trade    | Filled          | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     1 | 00000-1 | 4.0      | 4.0     | 102.0 |
    Then all rejections sent back to clients are
      | uid  | ordId | clOrdId | ordStatus | text                |
      | id1  |     1 | 00000-1 | Rejected  | Too late to replace |
  # no change in the order book
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 4.0 and shown 4.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 5.0     | 102.0  | 4.0       | 5.0    | 102.0 |
    And no market data snapshot for 912828Q45 is sent
