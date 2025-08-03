Feature: Cembalo - Cancel

  Background:
    Given the set of available instruments is
      | secId     | minQty | minQtyIncrement | minPriceIncrement | ordering | maxLevels |
      | 912828Q45 | 1.0    | 1.0             | 0.0078125         | 1        | 20        |
    And all books are initialized in open matching state
    And exchange starts with no active orders


  Scenario Outline: The only order in the stack gets canceled
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty   | qty  | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | <side> | <shownQty> | 7.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0   | bid0   | ask0   | askQ0   |
      | <bidQ0> | <bid0> | <ask0> | <askQ0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 7.0 and shown <shownQty> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty   | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty   | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty> | 7.0  | 102.0 | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    When a cancel request is received
      | ordId | clOrdId |
      |     1 | 00000-1 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | NaN   | 0.0   |
    And there are no continuous orders for instrument 912828Q45 and side <side> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty   | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <shownQty> | 7.0  | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | shownQty | bidQ0 | bid0  | ask0  | askQ0 |
      | Buy  | 7.0      | 7.0   | 102.0 | NaN   | 0.0   |
      | Buy  | 2.0      | 2.0   | 102.0 | NaN   | 0.0   |
      | Sell | 7.0      | 0.0   | NaN   | 102.0 | 7.0   |
      | Sell | 2.0      | 0.0   | NaN   | 102.0 | 2.0   |

  Scenario Outline: One level stack. Two orders. The first gets canceled.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 7.0 and shown <shownQty-i> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 11.0 and shown <shownQty-2> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

    When a cancel request is received
      | ordId | clOrdId |
      |     1 | 00000-1 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 4.0 and shown <shownQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | shownQty-i | shownQty-1 | shownQty-2 | bidQ0-0 | bid0-0  | ask0-0  | askQ0-0 | bidQ0-1 | bid0-1  | ask0-1  | askQ0-1 | bidQ0-2 | bid0-2  | ask0-2  | askQ0-2 |
      | Buy  | 7.0        | 4.0        | 11.0       | 7.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 4.0        | 6.0        | 2.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     |
      | Sell | 7.0        | 4.0        | 11.0       | 0.0     | NaN     | 102.0   | 7.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 4.0     |
      | Sell | 2.0        | 4.0        | 6.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 4.0     |
      | Buy  | 7.0        | 2.0        | 9.0        | 7.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 2.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 4.0        | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 2.0     | 102.0   | NaN     | 0.0     |
      | Sell | 7.0        | 2.0        | 9.0        | 0.0     | NaN     | 102.0   | 7.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 2.0     |
      | Sell | 2.0        | 2.0        | 4.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 2.0     |

  Scenario Outline: One level stack. Two orders. The second gets canceled.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 4.0 and shown <shownQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 11.0 and shown <shownQty-2> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    When a cancel request is received
      | ordId | clOrdId |
      |     2 | 00000-1 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 4.0 and shown <shownQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | shownQty-1 | shownQty-i | shownQty-2 | bidQ0-0 | bid0-0  | ask0-0  | askQ0-0 | bidQ0-1 | bid0-1  | ask0-1  | askQ0-1 | bidQ0-2 | bid0-2  | ask0-2  | askQ0-2 |
      | Buy  | 4.0        | 7.0        | 11.0       | 4.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 7.0        | 9.0        | 2.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 2.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 7.0        | 11.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 4.0     |
      | Sell | 2.0        | 7.0        | 9.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 2.0     |
      | Buy  | 4.0        | 2.0        | 6.0        | 4.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 4.0        | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 2.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 2.0        | 6.0        | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 4.0     |
      | Sell | 2.0        | 2.0        | 4.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 2.0     |

  Scenario Outline: One level stack. Three orders. The first gets canceled.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 7.0 and shown <shownQty-i> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 11.0 and shown <shownQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     3 | 00002-0 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 17.0 and shown <shownQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |

    When a cancel request is received
      | ordId | clOrdId |
      |     1 | 00000-1 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 10.0 and shown <shownQty-5> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | shownQty-i | shownQty-1 | shownQty-2 | shownQty-3 | shownQty-4 | shownQty-5 | bidQ0-0 | bid0-0  | ask0-0  | askQ0-0 | bidQ0-1 | bid0-1  | ask0-1  | askQ0-1 | bidQ0-2 | bid0-2  | ask0-2  | askQ0-2 | bidQ0-3 | bid0-3  | ask0-3  | askQ0-3 |
      | Buy  | 7.0        | 4.0        | 6.0        | 11.0       | 17.0       | 10.0       | 7.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 17.0    | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     |
      | Buy  | 7.0        | 2.0        | 6.0        | 9.0        | 15.0       | 8.0        | 7.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 15.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Sell | 7.0        | 4.0        | 6.0        | 11.0       | 17.0       | 10.0       | 0.0     | NaN     | 102.0   | 7.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 17.0    | 0.0     | NaN     | 102.0   | 10.0    |
      | Sell | 7.0        | 2.0        | 6.0        | 9.0        | 15.0       | 8.0        | 0.0     | NaN     | 102.0   | 7.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 15.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Buy  | 7.0        | 4.0        | 1.0        | 11.0       | 12.0       | 5.0        | 7.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 7.0        | 2.0        | 1.0        | 9.0        | 10.0       | 3.0        | 7.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     |
      | Sell | 7.0        | 4.0        | 1.0        | 11.0       | 12.0       | 5.0        | 0.0     | NaN     | 102.0   | 7.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 5.0     |
      | Sell | 7.0        | 2.0        | 1.0        | 9.0        | 10.0       | 3.0        | 0.0     | NaN     | 102.0   | 7.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 3.0     |
      | Buy  | 2.0        | 4.0        | 6.0        | 6.0        | 12.0       | 10.0       | 2.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 6.0        | 4.0        | 10.0       | 8.0        | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Sell | 2.0        | 4.0        | 6.0        | 6.0        | 12.0       | 10.0       | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 10.0    |
      | Sell | 2.0        | 2.0        | 6.0        | 4.0        | 10.0       | 8.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Buy  | 2.0        | 4.0        | 1.0        | 6.0        | 7.0        | 5.0        | 2.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 7.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 1.0        | 4.0        | 5.0        | 3.0        | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     |
      | Sell | 2.0        | 4.0        | 1.0        | 6.0        | 7.0        | 5.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 7.0     | 0.0     | NaN     | 102.0   | 5.0     |
      | Sell | 2.0        | 2.0        | 1.0        | 4.0        | 5.0        | 3.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 5.0     | 0.0     | NaN     | 102.0   | 3.0     |

  Scenario Outline: One level stack. Three orders. The second gets canceled.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 4.0 and shown <shownQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 11.0 and shown <shownQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     3 | 00002-0 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 17.0 and shown <shownQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |

    When a cancel request is received
      | ordId | clOrdId |
      |     2 | 00000-1 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 10.0 and shown <shownQty-5> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | shownQty-1 | shownQty-i | shownQty-2 | shownQty-3 | shownQty-4 | shownQty-5 | bidQ0-0 | bid0-0  | ask0-0  | askQ0-0 | bidQ0-1 | bid0-1  | ask0-1  | askQ0-1 | bidQ0-2 | bid0-2  | ask0-2  | askQ0-2 | bidQ0-3 | bid0-3  | ask0-3  | askQ0-3 |
      | Buy  | 4.0        | 7.0        | 6.0        | 11.0       | 17.0       | 10.0       | 4.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 17.0    | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 7.0        | 6.0        | 9.0        | 15.0       | 8.0        | 2.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 15.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 7.0        | 6.0        | 11.0       | 17.0       | 10.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 17.0    | 0.0     | NaN     | 102.0   | 10.0    |
      | Sell | 2.0        | 7.0        | 6.0        | 9.0        | 15.0       | 8.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 15.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Buy  | 4.0        | 2.0        | 6.0        | 6.0        | 12.0       | 10.0       | 4.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 6.0        | 4.0        | 10.0       | 8.0        | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 2.0        | 6.0        | 6.0        | 12.0       | 10.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 10.0    |
      | Sell | 2.0        | 2.0        | 6.0        | 4.0        | 10.0       | 8.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Buy  | 4.0        | 7.0        | 1.0        | 11.0       | 12.0       | 5.0        | 4.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 7.0        | 1.0        | 9.0        | 10.0       | 3.0        | 2.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 7.0        | 1.0        | 11.0       | 12.0       | 5.0        | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 5.0     |
      | Sell | 2.0        | 7.0        | 1.0        | 9.0        | 10.0       | 3.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 3.0     |
      | Buy  | 4.0        | 2.0        | 1.0        | 6.0        | 7.0        | 5.0        | 4.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 7.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 1.0        | 4.0        | 5.0        | 3.0        | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 2.0        | 1.0        | 6.0        | 7.0        | 5.0        | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 7.0     | 0.0     | NaN     | 102.0   | 5.0     |
      | Sell | 2.0        | 2.0        | 1.0        | 4.0        | 5.0        | 3.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 5.0     | 0.0     | NaN     | 102.0   | 3.0     |

  Scenario Outline: One level stack. Three orders. The last gets canceled.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 4.0 and shown <shownQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 10.0 and shown <shownQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     3 | 00000-0 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 17.0 and shown <shownQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     3 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    When a cancel request is received
      | ordId | clOrdId |
      |     3 | 00000-1 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 10.0 and shown <shownQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | shownQty-1 | shownQty-2 | shownQty-i | shownQty-3 | shownQty-4 | bidQ0-0 | bid0-0  | ask0-0  | askQ0-0 | bidQ0-1 | bid0-1  | ask0-1  | askQ0-1 | bidQ0-2 | bid0-2  | ask0-2  | askQ0-2 | bidQ0-3 | bid0-3  | ask0-3  | askQ0-3 |
      | Buy  | 4.0        | 6.0        | 7.0        | 10.0       | 17.0       | 4.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 17.0    | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 6.0        | 7.0        | 8.0        | 15.0       | 2.0     | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     | 15.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 6.0        | 7.0        | 10.0       | 17.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 17.0    | 0.0     | NaN     | 102.0   | 10.0    |
      | Sell | 2.0        | 6.0        | 7.0        | 8.0        | 15.0       | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 8.0     | 0.0     | NaN     | 102.0   | 15.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Buy  | 4.0        | 6.0        | 2.0        | 10.0       | 12.0       | 4.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 6.0        | 2.0        | 8.0        | 10.0       | 2.0     | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 6.0        | 2.0        | 10.0       | 12.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 10.0    |
      | Sell | 2.0        | 6.0        | 2.0        | 8.0        | 10.0       | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 8.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Buy  | 4.0        | 1.0        | 7.0        | 5.0        | 12.0       | 4.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 1.0        | 7.0        | 3.0        | 10.0       | 2.0     | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 1.0        | 7.0        | 5.0        | 12.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 5.0     | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 5.0     |
      | Sell | 2.0        | 1.0        | 7.0        | 3.0        | 10.0       | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 3.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 3.0     |
      | Buy  | 4.0        | 1.0        | 2.0        | 5.0        | 7.0        | 4.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     | 7.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 1.0        | 2.0        | 3.0        | 5.0        | 2.0     | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 1.0        | 2.0        | 5.0        | 7.0        | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 5.0     | 0.0     | NaN     | 102.0   | 7.0     | 0.0     | NaN     | 102.0   | 5.0     |
      | Sell | 2.0        | 1.0        | 2.0        | 3.0        | 5.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 3.0     | 0.0     | NaN     | 102.0   | 5.0     | 0.0     | NaN     | 102.0   | 3.0     |


  Scenario Outline: One level stack. Three orders belonging to the same user. User logs out.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 4.0 and shown <shownQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 11.0 and shown <shownQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     3 | 00002-0 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 17.0 and shown <shownQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |

    When user id1 logs out
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0 | ask0 | askQ0 |
      |   0.0 | NaN  | NaN  |   0.0 |
    And the continuous order book for 912828Q45 is empty
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text        |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 4.0       | 0.0    | NaN   | User logout |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 7.0       | 0.0    | NaN   | User logout |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 6.0       | 0.0    | NaN   | User logout |

    Examples: Relevant Combinations
      | side | shownQty-1 | shownQty-i | shownQty-2 | shownQty-3 | shownQty-4 | bidQ0-0 | bid0-0  | ask0-0  | askQ0-0 | bidQ0-1 | bid0-1  | ask0-1  | askQ0-1 | bidQ0-2 | bid0-2  | ask0-2  | askQ0-2 | bidQ0-3 | bid0-3  | ask0-3  | askQ0-3 |
      | Buy  | 4.0        | 7.0        | 6.0        | 11.0       | 17.0       | 4.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 17.0    | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 7.0        | 6.0        | 9.0        | 15.0       | 2.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 15.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 7.0        | 6.0        | 11.0       | 17.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 17.0    | 0.0     | NaN     | 102.0   | 10.0    |
      | Sell | 2.0        | 7.0        | 6.0        | 9.0        | 15.0       | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 15.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Buy  | 4.0        | 2.0        | 6.0        | 6.0        | 12.0       | 4.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 6.0        | 4.0        | 10.0       | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 2.0        | 6.0        | 6.0        | 12.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 10.0    |
      | Sell | 2.0        | 2.0        | 6.0        | 4.0        | 10.0       | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Buy  | 4.0        | 7.0        | 1.0        | 11.0       | 12.0       | 4.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 7.0        | 1.0        | 9.0        | 10.0       | 2.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 7.0        | 1.0        | 11.0       | 12.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 5.0     |
      | Sell | 2.0        | 7.0        | 1.0        | 9.0        | 10.0       | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 3.0     |
      | Buy  | 4.0        | 2.0        | 1.0        | 6.0        | 7.0        | 4.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 7.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 1.0        | 4.0        | 5.0        | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 2.0        | 1.0        | 6.0        | 7.0        | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 7.0     | 0.0     | NaN     | 102.0   | 5.0     |
      | Sell | 2.0        | 2.0        | 1.0        | 4.0        | 5.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 5.0     | 0.0     | NaN     | 102.0   | 3.0     |

  Scenario Outline: One level stack. Three orders belonging to the three users. First user logs out.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 4.0 and shown <shownQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id2 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 11.0 and shown <shownQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id2 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id2 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id3 | 912828Q45 |     3 | 00002-0 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 17.0 and shown <shownQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id2 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
      | id3 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id3 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |

    When user id1 logs out
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 13.0 and shown <shownQty-5> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id2 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
      | id3 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text        |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 4.0       | 0.0    | NaN   | User logout |

    Examples: Relevant Combinations
      | side | shownQty-1 | shownQty-i | shownQty-2 | shownQty-3 | shownQty-4 | shownQty-5 | bidQ0-0 | bid0-0  | ask0-0  | askQ0-0 | bidQ0-1 | bid0-1  | ask0-1  | askQ0-1 | bidQ0-2 | bid0-2  | ask0-2  | askQ0-2 | bidQ0-3 | bid0-3  | ask0-3  | askQ0-3 |
      | Buy  | 4.0        | 7.0        | 6.0        | 11.0       | 17.0       | 13.0       | 4.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 17.0    | 102.0   | NaN     | 0.0     | 13.0    | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 7.0        | 6.0        | 9.0        | 15.0       | 13.0       | 2.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 15.0    | 102.0   | NaN     | 0.0     | 13.0    | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 7.0        | 6.0        | 11.0       | 17.0       | 13.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 17.0    | 0.0     | NaN     | 102.0   | 13.0    |
      | Sell | 2.0        | 7.0        | 6.0        | 9.0        | 15.0       | 13.0       | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 15.0    | 0.0     | NaN     | 102.0   | 13.0    |
      | Buy  | 4.0        | 2.0        | 6.0        | 6.0        | 12.0       | 8.0        | 4.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 6.0        | 4.0        | 10.0       | 8.0        | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 2.0        | 6.0        | 6.0        | 12.0       | 8.0        | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Sell | 2.0        | 2.0        | 6.0        | 4.0        | 10.0       | 8.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Buy  | 4.0        | 7.0        | 1.0        | 11.0       | 12.0       | 8.0        | 4.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 7.0        | 1.0        | 9.0        | 10.0       | 8.0        | 2.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 7.0        | 1.0        | 11.0       | 12.0       | 8.0        | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Sell | 2.0        | 7.0        | 1.0        | 9.0        | 10.0       | 8.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Buy  | 4.0        | 2.0        | 1.0        | 6.0        | 7.0        | 3.0        | 4.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 7.0     | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 1.0        | 4.0        | 5.0        | 3.0        | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 2.0        | 1.0        | 6.0        | 7.0        | 3.0        | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 7.0     | 0.0     | NaN     | 102.0   | 3.0     |
      | Sell | 2.0        | 2.0        | 1.0        | 4.0        | 5.0        | 3.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 5.0     | 0.0     | NaN     | 102.0   | 3.0     |

  Scenario Outline: One level stack. Three orders belonging to the three users. Second user logs out.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 4.0 and shown <shownQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id2 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 11.0 and shown <shownQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id2 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id2 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id3 | 912828Q45 |     3 | 00002-0 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 17.0 and shown <shownQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id2 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
      | id3 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id3 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |

    When user id2 logs out
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 10.0 and shown <shownQty-5> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id3 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text        |
      | id2 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 7.0       | 0.0    | NaN   | User logout |

    Examples: Relevant Combinations
      | side | shownQty-1 | shownQty-i | shownQty-2 | shownQty-3 | shownQty-4 | shownQty-5 | bidQ0-0 | bid0-0  | ask0-0  | askQ0-0 | bidQ0-1 | bid0-1  | ask0-1  | askQ0-1 | bidQ0-2 | bid0-2  | ask0-2  | askQ0-2 | bidQ0-3 | bid0-3  | ask0-3  | askQ0-3 |
      | Buy  | 4.0        | 7.0        | 6.0        | 11.0       | 17.0       | 10.0       | 4.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 17.0    | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 7.0        | 6.0        | 9.0        | 15.0       | 8.0        | 2.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 15.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 7.0        | 6.0        | 11.0       | 17.0       | 10.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 17.0    | 0.0     | NaN     | 102.0   | 10.0    |
      | Sell | 2.0        | 7.0        | 6.0        | 9.0        | 15.0       | 8.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 15.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Buy  | 4.0        | 2.0        | 6.0        | 6.0        | 12.0       | 10.0       | 4.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 6.0        | 4.0        | 10.0       | 8.0        | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 8.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 2.0        | 6.0        | 6.0        | 12.0       | 10.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 10.0    |
      | Sell | 2.0        | 2.0        | 6.0        | 4.0        | 10.0       | 8.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 8.0     |
      | Buy  | 4.0        | 7.0        | 1.0        | 11.0       | 12.0       | 5.0        | 4.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 7.0        | 1.0        | 9.0        | 10.0       | 3.0        | 2.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 7.0        | 1.0        | 11.0       | 12.0       | 5.0        | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 5.0     |
      | Sell | 2.0        | 7.0        | 1.0        | 9.0        | 10.0       | 3.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 3.0     |
      | Buy  | 4.0        | 2.0        | 1.0        | 6.0        | 7.0        | 5.0        | 4.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 7.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 1.0        | 4.0        | 5.0        | 3.0        | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     | 3.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 2.0        | 1.0        | 6.0        | 7.0        | 5.0        | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 7.0     | 0.0     | NaN     | 102.0   | 5.0     |
      | Sell | 2.0        | 2.0        | 1.0        | 4.0        | 5.0        | 3.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 5.0     | 0.0     | NaN     | 102.0   | 3.0     |

  Scenario Outline: One level stack. Three orders belonging to the three users. Third user logs out.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 4.0 and shown <shownQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id2 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 11.0 and shown <shownQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id2 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id2 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 102.0 | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty     | qty  | price |
      | id3 | 912828Q45 |     3 | 00002-0 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 17.0 and shown <shownQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id2 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
      | id3 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id3 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |

    When user id3 logs out
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 11.0 and shown <shownQty-5> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-1> | 4.0  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id2 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-i> | 7.0  | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty     | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text        |
      | id3 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <shownQty-2> | 6.0  | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 6.0       | 0.0    | NaN   | User logout |

    Examples: Relevant Combinations
      | side | shownQty-1 | shownQty-i | shownQty-2 | shownQty-3 | shownQty-4 | shownQty-5 | bidQ0-0 | bid0-0  | ask0-0  | askQ0-0 | bidQ0-1 | bid0-1  | ask0-1  | askQ0-1 | bidQ0-2 | bid0-2  | ask0-2  | askQ0-2 | bidQ0-3 | bid0-3  | ask0-3  | askQ0-3 |
      | Buy  | 4.0        | 7.0        | 6.0        | 11.0       | 17.0       | 11.0       | 4.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 17.0    | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 7.0        | 6.0        | 9.0        | 15.0       | 9.0        | 2.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 15.0    | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 7.0        | 6.0        | 11.0       | 17.0       | 11.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 17.0    | 0.0     | NaN     | 102.0   | 11.0    |
      | Sell | 2.0        | 7.0        | 6.0        | 9.0        | 15.0       | 9.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 15.0    | 0.0     | NaN     | 102.0   | 9.0     |
      | Buy  | 4.0        | 2.0        | 6.0        | 6.0        | 12.0       | 6.0        | 4.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 6.0        | 4.0        | 10.0       | 4.0        | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 2.0        | 6.0        | 6.0        | 12.0       | 6.0        | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 6.0     |
      | Sell | 2.0        | 2.0        | 6.0        | 4.0        | 10.0       | 4.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 4.0     |
      | Buy  | 4.0        | 7.0        | 1.0        | 11.0       | 12.0       | 11.0       | 4.0     | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     | 12.0    | 102.0   | NaN     | 0.0     | 11.0    | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 7.0        | 1.0        | 9.0        | 10.0       | 9.0        | 2.0     | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     | 10.0    | 102.0   | NaN     | 0.0     | 9.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 7.0        | 1.0        | 11.0       | 12.0       | 11.0       | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 11.0    | 0.0     | NaN     | 102.0   | 12.0    | 0.0     | NaN     | 102.0   | 11.0    |
      | Sell | 2.0        | 7.0        | 1.0        | 9.0        | 10.0       | 9.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 9.0     | 0.0     | NaN     | 102.0   | 10.0    | 0.0     | NaN     | 102.0   | 9.0     |
      | Buy  | 4.0        | 2.0        | 1.0        | 6.0        | 7.0        | 6.0        | 4.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     | 7.0     | 102.0   | NaN     | 0.0     | 6.0     | 102.0   | NaN     | 0.0     |
      | Buy  | 2.0        | 2.0        | 1.0        | 4.0        | 5.0        | 4.0        | 2.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     | 5.0     | 102.0   | NaN     | 0.0     | 4.0     | 102.0   | NaN     | 0.0     |
      | Sell | 4.0        | 2.0        | 1.0        | 6.0        | 7.0        | 6.0        | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 6.0     | 0.0     | NaN     | 102.0   | 7.0     | 0.0     | NaN     | 102.0   | 6.0     |
      | Sell | 2.0        | 2.0        | 1.0        | 4.0        | 5.0        | 4.0        | 0.0     | NaN     | 102.0   | 2.0     | 0.0     | NaN     | 102.0   | 4.0     | 0.0     | NaN     | 102.0   | 5.0     | 0.0     | NaN     | 102.0   | 4.0     |

