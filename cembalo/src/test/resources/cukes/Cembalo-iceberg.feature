Feature: Cembalo - Iceberg

  Background:
    Given the set of available instruments is
      | secId     | minQty | minQtyIncrement | minPriceIncrement | ordering | maxLevels |
      | 912828Q45 | 1.0    | 1.0             | 0.0078125         | 1        | 20        |
    And all books are initialized in open matching state
    And exchange starts with no active orders

  Scenario: Iceberg fully executed against non iceberg
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 2.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 10.0 and shown 2.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Buy  | 3.0      | 3.0  | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 101.0 | 2.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 1 with price 101.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 101.0 | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | Sell | 10.0     | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 3.0   | 101.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 101.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Sell | 10.0     | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 | Trade    | Filled    | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Sell | 10.0     | 10.0 | 102.0 | Trade    | Filled    | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      |

  Scenario: Iceberg fully executed against iceberg
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 2.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 10.0 and shown 2.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Buy  | 3.0      | 3.0  | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 101.0 | 2.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 1 with price 101.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 101.0 | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | Sell | 1.0      | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 3.0   | 101.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 101.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Sell | 1.0      | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 | Trade    | Filled    | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Sell | 1.0      | 10.0 | 102.0 | Trade    | Filled    | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      |

  Scenario: Non iceberg fully executed against iceberg
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 10.0     | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 10.0  | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 10.0 and shown 10.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 10.0     | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 10.0     | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Buy  | 3.0      | 3.0  | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 101.0 | 10.0  | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 1 with price 101.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 101.0 | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | Sell | 1.0      | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 3.0   | 101.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 101.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Sell | 1.0      | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 10.0     | 10.0 | 102.0 | Trade    | Filled    | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Sell | 1.0      | 10.0 | 102.0 | Trade    | Filled    | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      |

  Scenario: Multiple icebergs executed against one iceberg
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 2.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 10.0 and shown 2.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Buy  | 3.0      | 3.0  | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 101.0 | 2.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 1 with price 101.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 101.0 | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | Buy  | 3.0      | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 101.0 | 5.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 20.0 and shown 5.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     4 | 00004-0 | Limit   | DAY | Sell | 3.0      | 3.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 101.0 | 5.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 17.0 and shown 5.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 1.0     | 102.0  | 9.0       | 1.0    | 102.0 |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 3.0      | 3.0  | 102.0 | New      | New             | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 | Trade    | PartiallyFilled | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 102.0 | Trade    | PartiallyFilled | 1.0     | 102.0  | 9.0       | 1.0    | 102.0 |      |
      | id1 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 3.0      | 3.0  | 102.0 | Trade    | Filled          | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      |

  Scenario: Iceberg replacement
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 2.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 10.0 and shown 2.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Buy  | 3.0      | 3.0  | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 101.0 | 2.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 1 with price 101.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 101.0 | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

	# shown size increase in a one element level has no effect
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     1 | 00001-1 | 3.0      | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 101.0 | 3.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 10.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-1 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-1 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 102.0 | Replaced | Replaced  | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | Buy  | 5.0      | 5.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 101.0 | 8.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 15.0 and shown 8.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-1 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0  | 102.0 | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |

	# shown size reduction has no effect
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     1 | 00001-2 | 2.0      | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 101.0 | 7.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 15.0 and shown 7.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-2 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-2 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 | Replaced | Replaced  | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

	# shown size increase results in queue position change
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     1 | 00001-3 | 3.0      | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 101.0 | 8.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 15.0 and shown 8.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id1 |     1 | 00001-3 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-3 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 102.0 | Replaced | Replaced  | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

  # price change results in level change
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     1 | 00001-4 | 3.0      | 10.0 | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 6.0   | 101.0 | 5.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 5.0 and shown 5.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side Buy at level 1 with price 101.0 and leaves 13.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     1 | 00001-4 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-4 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 101.0 | Replaced | Replaced  | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

  # price change results in level change
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     1 | 00001-5 | 3.0      | 10.0 | 100.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2 | bid2  | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 100.0 | 3.0   | 101.0 | 5.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 5.0 and shown 5.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side Buy at level 1 with price 101.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side Buy at level 2 with price 100.0 and leaves 10.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-5 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-5 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 100.0 | Replaced | Replaced  | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

  # price change results in level change
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     1 | 00001-6 | 3.0      | 10.0 | 99.0  |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2 | bid2  | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 99.0  | 3.0   | 101.0 | 5.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 5.0 and shown 5.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side Buy at level 1 with price 101.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side Buy at level 2 with price 99.0 and leaves 10.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-6 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-6 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 99.0  | Replaced | Replaced  | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

  # price change results in level change
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     1 | 00001-7 | 3.0      | 10.0 | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 6.0   | 101.0 | 5.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 5.0 and shown 5.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side Buy at level 1 with price 101.0 and leaves 13.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     1 | 00001-7 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-7 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 101.0 | Replaced | Replaced  | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

  # price change results in level change
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     3 | 00003-1 | 5.0      | 5.0  | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 11.0  | 101.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 101.0 and leaves 18.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     1 | 00001-7 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
      | id1 |     3 | 00003-1 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00003-1 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0  | 101.0 | Replaced | Replaced  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |

  # more price changes
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     2 | 00002-1 | 4.0      | 4.0  | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 12.0  | 101.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 101.0 and leaves 19.0 and shown 12.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-7 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
      | id1 |     3 | 00003-1 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-1 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00002-1 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 4.0  | 101.0 | Replaced | Replaced  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

  # more price changes
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     1 | 00001-8 | 3.0      | 20.0 | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 12.0  | 101.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 101.0 and leaves 29.0 and shown 12.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-8 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 20.0 | 0.0     | NaN    | 20.0      | 0.0    | NaN   |
      | id1 |     3 | 00003-1 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-1 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-8 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 20.0 | 101.0 | Replaced | Replaced  | 0.0     | NaN    | 20.0      | 0.0    | NaN   |      |

  # more price changes
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     1 | 00001-9 | 4.0      | 10.0 | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 13.0  | 101.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 101.0 and leaves 19.0 and shown 13.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     3 | 00003-1 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-1 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     1 | 00001-9 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-9 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 10.0 | 101.0 | Replaced | Replaced  | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

  # more price changes
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     3 | 00003-2 | 4.0      | 20.0 | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 12.0  | 101.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 101.0 and leaves 34.0 and shown 12.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     3 | 00003-2 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 20.0 | 0.0     | NaN    | 20.0      | 0.0    | NaN   |
      | id1 |     2 | 00002-1 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     1 | 00001-9 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00003-2 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 20.0 | 101.0 | Replaced | Replaced  | 0.0     | NaN    | 20.0      | 0.0    | NaN   |      |

  # more price changes
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     3 | 00003-3 | 4.0      | 10.0 | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 12.0  | 101.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 101.0 and leaves 24.0 and shown 12.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     3 | 00003-3 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
      | id1 |     2 | 00002-1 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     1 | 00001-9 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00003-3 | 912828Q45 | Limit   | DAY | Buy  | 4.0      | 10.0 | 101.0 | Replaced | Replaced  | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

  Scenario: Iceberg order execution
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Sell | 7.0      | 7.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 0.0   | NaN   | 102.0 | 7.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Sell at level 0 with price 102.0 and leaves 7.0 and shown 7.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Sell | 7.0      | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Sell | 7.0      | 7.0  | 102.0 | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Buy  | 3.0      | 3.0  | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 3.0   | 101.0 | 102.0 | 7.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 101.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 101.0 | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 101.0 | 2.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 3.0 and shown 2.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 7.0     | 102.0  | 3.0       | 7.0    | 102.0 |
    And the continuous orders for 912828Q45 and side Buy at level 1 with price 101.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 | New      | New             | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Sell | 7.0      | 7.0  | 102.0 | Trade    | Filled          | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 102.0 | Trade    | PartiallyFilled | 7.0     | 102.0  | 3.0       | 7.0    | 102.0 |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty  | price |
      |     3 | 00003-1 | 3.0      | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 3.0   | 101.0 | 3.0   | 102.0 | NaN   | 0.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     3 | 00003-1 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 0.0     | NaN    | 3.0       | 7.0    | 102.0 |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00003-1 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 102.0 | Replaced | Replaced  | 0.0     | NaN    | 3.0       | 7.0    | 102.0 |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price |
      | id1 | 912828Q45 |     4 | 00004-0 | Limit   | DAY | Sell | 10.0     | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 0.0   | NaN   | 3.0   | 101.0 | 102.0 | 7.0   | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 101.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 3.0  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side Sell at level 0 with price 102.0 and leaves 7.0 and shown 7.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 10.0     | 10.0 | 3.0     | 102.0  | 7.0       | 3.0    | 102.0 |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 10.0     | 10.0 | 102.0 | New      | New             | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id1 |     3 | 00003-1 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 10.0 | 102.0 | Trade    | Filled          | 3.0     | 102.0  | 0.0       | 10.0   | 102.0 |      |
      | id1 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 10.0     | 10.0 | 102.0 | Trade    | PartiallyFilled | 3.0     | 102.0  | 7.0       | 3.0    | 102.0 |      |

