Feature: Cembalo - Auction and Continuous Orders

  Background:
    Given the set of available instruments is
      | secId     | minQty | minQtyIncrement | minPriceIncrement | ordering | maxLevels |
      | 912828Q45 | 1.0    | 1.0             | 0.0078125         | 1        | 20        |
    And all books are initialized in open matching state
    And exchange starts with no active orders


  Scenario: Continuous orders in Non-Matching phase and Open Auction orders - AtOpen orders are matched, DAY orders are transferred
  Both order types are included in the calculaton of imbalance and auction numbers
  After auction non matched auction orders are canceled and non matched continuous orders are transfered to the continuous book

    Given the continuous order book receives a non_matching timer event

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif    | side | shownQty | qty  | price |
      | id01 | 912828Q45 |     1 | 00001-0 | Market  | AtOpen | Buy  |      0.0 | 12.0 |   NaN |
      | id02 | 912828Q45 |     2 | 00001-0 | Limit   | DAY    | Sell |      5.0 | 15.0 | 106.0 |
      | id03 | 912828Q45 |     3 | 00001-0 | Limit   | AtOpen | Buy  |      0.0 |  2.0 | 105.0 |
      | id04 | 912828Q45 |     4 | 00001-0 | Limit   | DAY    | Sell |     12.0 | 12.0 | 105.0 |
      | id05 | 912828Q45 |     5 | 00001-0 | Limit   | AtOpen | Buy  |      0.0 |  4.0 | 104.0 |
      | id06 | 912828Q45 |     6 | 00001-0 | Limit   | AtOpen | Sell |      0.0 |  1.0 | 104.0 |
      | id07 | 912828Q45 |     7 | 00001-0 | Limit   | DAY    | Buy  |      1.0 |  1.0 | 103.0 |
      | id08 | 912828Q45 |     8 | 00001-0 | Limit   | AtOpen | Sell |      0.0 |  5.0 | 103.0 |
      | id09 | 912828Q45 |     9 | 00001-0 | Limit   | DAY    | Buy  |      2.0 | 10.0 | 102.0 |
      | id10 | 912828Q45 |    10 | 00001-0 | Limit   | AtOpen | Sell |      0.0 |  5.0 | 102.0 |
      | id11 | 912828Q45 |    11 | 00001-0 | Limit   | DAY    | Buy  |     10.0 | 10.0 | 101.0 |
      | id12 | 912828Q45 |    12 | 00001-0 | Market  | AtOpen | Sell |      0.0 |  5.0 |   NaN |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  |      0.0 | 12.0 |   NaN | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | DAY    | Sell |      5.0 | 15.0 | 106.0 | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 |  2.0 | 105.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | DAY    | Sell |     12.0 | 12.0 | 105.0 | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 |  4.0 | 104.0 | New      | New       | 0.0     | NaN    |  4.0      | 0.0    | NaN   |      |
      | id06 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |      0.0 |  1.0 | 104.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id07 |     7 | 00001-0 | 912828Q45 | Limit   | DAY    | Buy  |      1.0 |  1.0 | 103.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id08 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |      0.0 |  5.0 | 103.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id09 |     9 | 00001-0 | 912828Q45 | Limit   | DAY    | Buy  |      2.0 | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id10 |    10 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |      0.0 |  5.0 | 102.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id11 |    11 | 00001-0 | 912828Q45 | Limit   | DAY    | Buy  |     10.0 | 10.0 | 101.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |      0.0 |  5.0 |   NaN | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |    12.0 |       0.0 |        12.0 |          43.0 |    12.0 |    31.0 | Sell        |
      | 106.0 |     0.0 |      15.0 |        12.0 |          43.0 |    12.0 |    31.0 | Sell        |
      | 105.0 |     2.0 |      12.0 |        14.0 |          28.0 |    14.0 |    14.0 | Sell        |
      | 104.0 |     4.0 |       1.0 |        18.0 |          16.0 |    16.0 |     2.0 | Buy         |
      | 103.0 |     1.0 |       5.0 |        19.0 |          15.0 |    15.0 |     4.0 | Buy         |
      | 102.0 |    10.0 |       5.0 |        29.0 |          10.0 |    10.0 |    19.0 | Buy         |
      | 101.0 |    10.0 |       0.0 |        39.0 |           5.0 |     5.0 |    34.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        39.0 |           5.0 |     5.0 |    34.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    16.0 |     2.0 | Buy  |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price 104.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Sell and price -Inf are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |

    When the open order book receives an auction timer event
    And the continuous order book receives a matching timer event
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 12.0 |   NaN | Trade    | Filled          | 12.0    | 104.0  | 0.0       | 12.0   | 104.0 |                     |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 2.0  | 105.0 | Trade    | Filled          | 2.0     | 104.0  | 0.0       | 2.0    | 104.0 |                     |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 4.0  | 104.0 | Trade    | PartiallyFilled | 2.0     | 104.0  | 2.0       | 2.0    | 104.0 |                     |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 4.0  | 104.0 | Canceled | Canceled        | 0.0     | NaN    | 2.0       | 2.0    | 104.0 | No match in auction |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell | 5.0  |   NaN | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id10 |    10 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 5.0  | 102.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id08 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 5.0  | 103.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id06 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 1.0  | 104.0 | Trade    | Filled          | 1.0     | 104.0  | 0.0       | 1.0    | 104.0 |                     |

    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2 | bid2  | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 10.0  | 101.0 | 2.0   | 102.0 | 1.0   | 103.0 | 105.0 | 12.0  | 106.0 | 5.0   |

    And the continuous orders for 912828Q45 and side Buy at level 0 with price 103.0 and leaves 1.0 and shown 1.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id07 |     7 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0  | 0.0     | NaN    | 1.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side Buy at level 1 with price 102.0 and leaves 10.0 and shown 2.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id09 |     9 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side Buy at level 2 with price 101.0 and leaves 10.0 and shown 10.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id11 |    11 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 10.0     | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |

    And the continuous orders for 912828Q45 and side Sell at level 0 with price 105.0 and leaves 12.0 and shown 12.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | DAY | Sell | 12.0     | 12.0 | 0.0     | NaN    | 12.0      | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side Sell at level 1 with price 106.0 and leaves 15.0 and shown 5.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 15.0 | 0.0     | NaN    | 15.0      | 0.0    | NaN   |


  Scenario: Continuous orders in Non-Matching phase and Open Auction orders - AtOpen orders are canceled, DAY orders are matched
  Both order types are included in the calculaton of imbalance and auction numbers
  After auction non matched auction orders are canceled and non matched continuous orders are transfered to the continuous book

    Given the continuous order book receives a non_matching timer event

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif    | side | shownQty | qty  | price |
      | id01 | 912828Q45 |     1 | 00001-0 | Market  | AtOpen | Buy  |      0.0 | 12.0 |   NaN |
      | id02 | 912828Q45 |     2 | 00001-0 | Limit   | AtOpen | Sell |      0.0 | 15.0 | 106.0 |
      | id03 | 912828Q45 |     3 | 00001-0 | Limit   | DAY    | Buy  |      1.0 |  2.0 | 105.0 |
      | id04 | 912828Q45 |     4 | 00001-0 | Limit   | AtOpen | Sell |      0.0 | 12.0 | 105.0 |
      | id05 | 912828Q45 |     5 | 00001-0 | Limit   | DAY    | Buy  |      2.0 |  4.0 | 104.0 |
      | id06 | 912828Q45 |     6 | 00001-0 | Limit   | DAY    | Sell |      1.0 |  1.0 | 104.0 |
      | id07 | 912828Q45 |     7 | 00001-0 | Limit   | AtOpen | Buy  |      0.0 |  1.0 | 103.0 |
      | id08 | 912828Q45 |     8 | 00001-0 | Limit   | DAY    | Sell |      5.0 |  5.0 | 103.0 |
      | id09 | 912828Q45 |     9 | 00001-0 | Limit   | AtOpen | Buy  |      0.0 | 10.0 | 102.0 |
      | id10 | 912828Q45 |    10 | 00001-0 | Limit   | DAY    | Sell |      5.0 |  5.0 | 102.0 |
      | id11 | 912828Q45 |    11 | 00001-0 | Limit   | AtOpen | Buy  |      0.0 | 10.0 | 101.0 |
      | id12 | 912828Q45 |    12 | 00001-0 | Market  | AtOpen | Sell |      0.0 |  5.0 |   NaN |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  |      0.0 | 12.0 |   NaN | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |      0.0 | 15.0 | 106.0 | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | DAY    | Buy  |      1.0 |  2.0 | 105.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |      0.0 | 12.0 | 105.0 | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | DAY    | Buy  |      2.0 |  4.0 | 104.0 | New      | New       | 0.0     | NaN    |  4.0      | 0.0    | NaN   |      |
      | id06 |     6 | 00001-0 | 912828Q45 | Limit   | DAY    | Sell |      1.0 |  1.0 | 104.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id07 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 |  1.0 | 103.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id08 |     8 | 00001-0 | 912828Q45 | Limit   | DAY    | Sell |      5.0 |  5.0 | 103.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id09 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id10 |    10 | 00001-0 | 912828Q45 | Limit   | DAY    | Sell |      5.0 |  5.0 | 102.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id11 |    11 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 | 10.0 | 101.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |      0.0 |  5.0 |   NaN | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |    12.0 |       0.0 |        12.0 |          43.0 |    12.0 |    31.0 | Sell        |
      | 106.0 |     0.0 |      15.0 |        12.0 |          43.0 |    12.0 |    31.0 | Sell        |
      | 105.0 |     2.0 |      12.0 |        14.0 |          28.0 |    14.0 |    14.0 | Sell        |
      | 104.0 |     4.0 |       1.0 |        18.0 |          16.0 |    16.0 |     2.0 | Buy         |
      | 103.0 |     1.0 |       5.0 |        19.0 |          15.0 |    15.0 |     4.0 | Buy         |
      | 102.0 |    10.0 |       5.0 |        29.0 |          10.0 |    10.0 |    19.0 | Buy         |
      | 101.0 |    10.0 |       0.0 |        39.0 |           5.0 |     5.0 |    34.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        39.0 |           5.0 |     5.0 |    34.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    16.0 |     2.0 | Buy  |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price 104.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | DAY    | Buy  |      2.0 | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Sell and price -Inf are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |      0.0 | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |

    When the open order book receives an auction timer event
    And the continuous order book receives a matching timer event
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | shownQty | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  |      0.0 | 12.0 |   NaN | Trade    | Filled          | 12.0    | 104.0  | 0.0       | 12.0   | 104.0 |                     |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | DAY    | Buy  |      1.0 | 2.0  | 105.0 | Trade    | Filled          | 2.0     | 104.0  | 0.0       | 2.0    | 104.0 |                     |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | DAY    | Buy  |      2.0 | 4.0  | 104.0 | Trade    | PartiallyFilled | 2.0     | 104.0  | 2.0       | 2.0    | 104.0 |                     |
      | id07 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 | 1.0  | 103.0 | Canceled | Canceled        | 0.0     | NaN    | 1.0       | 0.0    | NaN   | No match in auction |
      | id09 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 | 10.0 | 102.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id11 |    11 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 | 10.0 | 101.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |      0.0 | 5.0  |   NaN | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id10 |    10 | 00001-0 | 912828Q45 | Limit   | DAY    | Sell |      5.0 | 5.0  | 102.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id08 |     8 | 00001-0 | 912828Q45 | Limit   | DAY    | Sell |      5.0 | 5.0  | 103.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id06 |     6 | 00001-0 | 912828Q45 | Limit   | DAY    | Sell |      1.0 | 1.0  | 104.0 | Trade    | Filled          | 1.0     | 104.0  | 0.0       | 1.0    | 104.0 |                     |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |      0.0 | 12.0 | 105.0 | Canceled | Canceled        | 0.0     | NaN    | 12.0      | 0.0    | NaN   | No match in auction |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |      0.0 | 15.0 | 106.0 | Canceled | Canceled        | 0.0     | NaN    | 15.0      | 0.0    | NaN   | No match in auction |

    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  |
      | 2.0   | 104.0 |

    And the continuous orders for 912828Q45 and side Buy at level 0 with price 104.0 and leaves 2.0 and shown 2.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 4.0  | 0.0     | NaN    | 2.0       | 2.0    | 104.0 |

  Scenario: Continuous orders and Close Auction orders - At auction time all non matched orders are canceled

    Given the open order book receives a close timer event
  # Continuous book is in 'matching' phase
  # Close Auction book is in 'all' phase

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif     | side | shownQty | qty  | price |
      | id01 | 912828Q45 |     1 | 00001-0 | Market  | AtClose | Buy  |      0.0 | 12.0 |   NaN |
      | id02 | 912828Q45 |     2 | 00001-0 | Limit   | DAY     | Sell |      5.0 | 15.0 | 106.0 |
      | id03 | 912828Q45 |     3 | 00001-0 | Limit   | AtClose | Buy  |      0.0 |  2.0 | 105.0 |
      | id04 | 912828Q45 |     4 | 00001-0 | Limit   | DAY     | Sell |     12.0 | 12.0 | 105.0 |
      | id05 | 912828Q45 |     5 | 00001-0 | Limit   | AtClose | Buy  |      0.0 |  4.0 | 104.0 |
      | id06 | 912828Q45 |     6 | 00001-0 | Limit   | AtClose | Sell |      0.0 |  1.0 | 104.0 |
      | id07 | 912828Q45 |     7 | 00001-0 | Limit   | DAY     | Buy  |      1.0 |  1.0 | 103.0 |
      | id08 | 912828Q45 |     8 | 00001-0 | Limit   | AtClose | Sell |      0.0 |  5.0 | 103.0 |
      | id09 | 912828Q45 |     9 | 00001-0 | Limit   | DAY     | Buy  |      2.0 | 10.0 | 102.0 |
      | id10 | 912828Q45 |    10 | 00001-0 | Limit   | AtClose | Sell |      0.0 |  5.0 | 102.0 |
      | id11 | 912828Q45 |    11 | 00001-0 | Limit   | DAY     | Buy  |     10.0 | 10.0 | 101.0 |
      | id12 | 912828Q45 |    12 | 00001-0 | Market  | AtClose | Sell |      0.0 |  5.0 |   NaN |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtClose | Buy  |      0.0 | 12.0 |   NaN | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | DAY     | Sell |      5.0 | 15.0 | 106.0 | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 |  2.0 | 105.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | DAY     | Sell |     12.0 | 12.0 | 105.0 | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 |  4.0 | 104.0 | New      | New       | 0.0     | NaN    |  4.0      | 0.0    | NaN   |      |
      | id06 |     6 | 00001-0 | 912828Q45 | Limit   | AtClose | Sell |      0.0 |  1.0 | 104.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id07 |     7 | 00001-0 | 912828Q45 | Limit   | DAY     | Buy  |      1.0 |  1.0 | 103.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id08 |     8 | 00001-0 | 912828Q45 | Limit   | AtClose | Sell |      0.0 |  5.0 | 103.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id09 |     9 | 00001-0 | 912828Q45 | Limit   | DAY     | Buy  |      2.0 | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id10 |    10 | 00001-0 | 912828Q45 | Limit   | AtClose | Sell |      0.0 |  5.0 | 102.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id11 |    11 | 00001-0 | 912828Q45 | Limit   | DAY     | Buy  |     10.0 | 10.0 | 101.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtClose | Sell |      0.0 |  5.0 |   NaN | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2 | bid2  | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 10.0  | 101.0 | 2.0   | 102.0 | 1.0   | 103.0 | 105.0 | 12.0  | 106.0 | 5.0   |

    When the close order book receives an imbalance timer event
    Then the close accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |    12.0 |       0.0 |        12.0 |          43.0 |    12.0 |    31.0 | Sell        |
      | 106.0 |     0.0 |      15.0 |        12.0 |          43.0 |    12.0 |    31.0 | Sell        |
      | 105.0 |     2.0 |      12.0 |        14.0 |          28.0 |    14.0 |    14.0 | Sell        |
      | 104.0 |     4.0 |       1.0 |        18.0 |          16.0 |    16.0 |     2.0 | Buy         |
      | 103.0 |     1.0 |       5.0 |        19.0 |          15.0 |    15.0 |     4.0 | Buy         |
      | 102.0 |    10.0 |       5.0 |        29.0 |          10.0 |    10.0 |    19.0 | Buy         |
      | 101.0 |    10.0 |       0.0 |        39.0 |           5.0 |     5.0 |    34.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        39.0 |           5.0 |     5.0 |    34.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    16.0 |     2.0 | Buy  |
    And the accumulated orders for 912828Q45 and the close order book filtered by side Buy and price 104.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtClose | Buy  | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And the accumulated orders for 912828Q45 and the close order book filtered by side Sell and price -Inf are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtClose | Sell | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |

    When the close order book receives an auction timer event
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtClose | Buy  |      0.0 | 12.0 |   NaN | Trade    | Filled          | 12.0    | 104.0  | 0.0       | 12.0   | 104.0 |                     |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 | 2.0  | 105.0 | Trade    | Filled          | 2.0     | 104.0  | 0.0       | 2.0    | 104.0 |                     |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 | 4.0  | 104.0 | Trade    | PartiallyFilled | 2.0     | 104.0  | 2.0       | 2.0    | 104.0 |                     |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 | 4.0  | 104.0 | Canceled | Canceled        | 0.0     | NaN    | 2.0       | 2.0    | 104.0 | No match in auction |
      | id07 |     7 | 00001-0 | 912828Q45 | Limit   | DAY     | Buy  |      1.0 | 1.0  | 103.0 | Canceled | Canceled        | 0.0     | NaN    | 1.0       | 0.0    | NaN   | No match in auction |
      | id09 |     9 | 00001-0 | 912828Q45 | Limit   | DAY     | Buy  |      2.0 | 10.0 | 102.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id11 |    11 | 00001-0 | 912828Q45 | Limit   | DAY     | Buy  |     10.0 | 10.0 | 101.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtClose | Sell |      0.0 | 5.0  |   NaN | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id10 |    10 | 00001-0 | 912828Q45 | Limit   | AtClose | Sell |      0.0 | 5.0  | 102.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id08 |     8 | 00001-0 | 912828Q45 | Limit   | AtClose | Sell |      0.0 | 5.0  | 103.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id06 |     6 | 00001-0 | 912828Q45 | Limit   | AtClose | Sell |      0.0 | 1.0  | 104.0 | Trade    | Filled          | 1.0     | 104.0  | 0.0       | 1.0    | 104.0 |                     |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | DAY     | Sell |     12.0 | 12.0 | 105.0 | Canceled | Canceled        | 0.0     | NaN    | 12.0      | 0.0    | NaN   | No match in auction |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | DAY     | Sell |      5.0 | 15.0 | 106.0 | Canceled | Canceled        | 0.0     | NaN    | 15.0      | 0.0    | NaN   | No match in auction |

  # the continuous order book is now empty
    And there are no continuous orders for instrument 912828Q45 and side Buy at level 0
    And there are no continuous orders for instrument 912828Q45 and side Sell at level 0

    And a market data snapshot for 912828Q45 is sent to subscribers
  # the final empty snapshot
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | NaN   | 0.0   |


  Scenario: Full day scenario, both auction and continuous orders

# market is closed, i.e., all books are closed
    Given the open order book receives a close timer event
    And the continuous order book receives a close timer event
    And the close order book receives a close timer event

  # all orders are rejected
  # rejected orders are not assigned an order id
    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif     | side | shownQty | qty  | price |
      | id01 | 912828Q45 |     0 | 00000-0 | Market  | AtOpen  | Buy  |      0.0 | 12.0 |   NaN |
      | id02 | 912828Q45 |     0 | 00000-0 | Limit   | DAY     | Sell |      5.0 | 15.0 | 106.0 |
      | id03 | 912828Q45 |     0 | 00000-0 | Market  | AtClose | Buy  |      0.0 |  2.0 | 105.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text                 |
      | id01 |     0 | 00000-0 | 912828Q45 | Market  | AtOpen  | Buy  |      0.0 | 12.0 |   NaN | Rejected | Rejected  | 0.0     | NaN    | 12.0      | 0.0    | NaN   | Instrument is CLOSED |
      | id02 |     0 | 00000-0 | 912828Q45 | Limit   | DAY     | Sell |      5.0 | 15.0 | 106.0 | Rejected | Rejected  | 0.0     | NaN    | 15.0      | 0.0    | NaN   | Instrument is CLOSED |
      | id03 |     0 | 00000-0 | 912828Q45 | Market  | AtClose | Buy  |      0.0 |  2.0 | 105.0 | Rejected | Rejected  | 0.0     | NaN    |  2.0      | 0.0    | NaN   | Instrument is CLOSED |


# market is open, i.e., all books are open and phases are as specified
    Given the open order book receives an open timer event
    And the open order book receives an all timer event
    And the continuous order book receives an open timer event
    And the continuous order book receives a non_matching timer event
    And the close order book receives an open timer event
    And the close order book receives an all timer event

  # all orders are accepted
    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif     | side | shownQty | qty  | price |
      | id01 | 912828Q45 |     1 | 00001-0 | Market  | AtOpen  | Buy  |      0.0 | 12.0 |   NaN |
      | id02 | 912828Q45 |     2 | 00001-0 | Limit   | DAY     | Sell |      5.0 | 15.0 | 106.0 |
      | id03 | 912828Q45 |     3 | 00001-0 | Market  | AtClose | Buy  |      0.0 |  2.0 |   NaN |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen  | Buy  |      0.0 | 12.0 |   NaN | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | DAY     | Sell |      5.0 | 15.0 | 106.0 | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id03 |     3 | 00001-0 | 912828Q45 | Market  | AtClose | Buy  |      0.0 |  2.0 |   NaN | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |

  # amends are also accepted
    When a replacement request is received
      | ordId | clOrdId | ordType | shownQty | qty | price |
      |     1 | 00001-1 | Market  |      2.0 | 5.0 |   NaN |
      |     2 | 00001-1 | Limit   |      3.0 | 5.0 | 105.0 |
      |     3 | 00001-1 | Market  |      1.0 | 5.0 |   NaN |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     1 | 00001-1 | 912828Q45 | Market  | AtOpen  | Buy  |      2.0 |  5.0 |   NaN | Replaced | Replaced  | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id02 |     2 | 00001-1 | 912828Q45 | Limit   | DAY     | Sell |      3.0 |  5.0 | 105.0 | Replaced | Replaced  | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id03 |     3 | 00001-1 | 912828Q45 | Market  | AtClose | Buy  |      1.0 |  5.0 |   NaN | Replaced | Replaced  | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price Inf are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id01 |     1 | 00001-1 | 912828Q45 | Market  | AtOpen  | Buy  |      2.0 | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the accumulated orders for 912828Q45 and the close order book filtered by side Buy and price Inf are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id03 |     3 | 00001-1 | 912828Q45 | Market  | AtClose | Buy  |      1.0 | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
  # these are the continuous orders in the accumulated order book (continuous book is in non matching phase)
    And the accumulated orders for 912828Q45 and the continuous order book filtered by side Sell and price 105.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id02 |     2 | 00001-1 | 912828Q45 | Limit   | DAY     | Sell |      3.0 | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |

  # cancels are also accepted
    When a cancel request is received
      | ordId | clOrdId |
      |     1 | 00001-2 |
      |     2 | 00001-2 |
      |     3 | 00001-2 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     1 | 00001-2 | 912828Q45 | Market  | AtOpen  | Buy  |      2.0 |  5.0 |   NaN | Canceled | Canceled  | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id02 |     2 | 00001-2 | 912828Q45 | Limit   | DAY     | Sell |      3.0 |  5.0 | 105.0 | Canceled | Canceled  | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id03 |     3 | 00001-2 | 912828Q45 | Market  | AtClose | Buy  |      1.0 |  5.0 |   NaN | Canceled | Canceled  | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
    And the open accumulating order book for 912828Q45 is empty
    And the close accumulating order book for 912828Q45 is empty
    And the continuous accumulating order book for 912828Q45 is empty

# open order book transitions to 'only_new' phase
# continuous order book is still in 'non_matching' phase
# close order book is still in 'all' phase
    Given the open order book receives an only_new timer event

  # all orders are accepted
    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif     | side | shownQty | qty  | price |
      | id01 | 912828Q45 |     4 | 00002-0 | Limit   | AtOpen  | Buy  |      0.0 |  2.0 | 106.0 |
      | id02 | 912828Q45 |     5 | 00002-0 | Limit   | DAY     | Sell |      5.0 | 15.0 | 106.0 |
      | id03 | 912828Q45 |     6 | 00002-0 | Limit   | AtClose | Buy  |      0.0 |  2.0 | 106.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     4 | 00002-0 | 912828Q45 | Limit   | AtOpen  | Buy  |      0.0 |  2.0 | 106.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
      | id02 |     5 | 00002-0 | 912828Q45 | Limit   | DAY     | Sell |      5.0 | 15.0 | 106.0 | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id03 |     6 | 00002-0 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 |  2.0 | 106.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |

  # only AtOpen amend is rejected, the others are executed
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty | price | ordType |
      |     4 | 00002-1 |      0.0 | 9.0 | 105.0 | Limit   |
      |     5 | 00002-1 |      1.0 | 9.0 | 105.0 | Limit   |
      |     6 | 00002-1 |      0.0 | 9.0 | 105.0 | Limit   |
    Then all rejections sent back to clients are
      | uid  | ordId | clOrdId | ordStatus | text                                |
      | id01 |     4 | 00002-1 | Rejected  | Amend not allowed in Only New phase |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price 106.0 are
  # the order book has not changed
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id01 |     4 | 00002-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 |  2.0 | 0.0     | NaN    |  2.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id02 |     5 | 00002-1 | 912828Q45 | Limit   | DAY     | Sell | 1.0      | 9.0 | 105.0 | Replaced | Replaced  | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |
      | id03 |     6 | 00002-1 | 912828Q45 | Limit   | AtClose | Buy  | 0.0      | 9.0 | 105.0 | Replaced | Replaced  | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

  # only AtOpen cancel is rejected, the others are executed
    When a cancel request is received
      | ordId | clOrdId |
      |     4 | 00002-2 |
      |     5 | 00002-2 |
      |     6 | 00002-2 |
    Then all rejections sent back to clients are
      | uid  | ordId | clOrdId | ordStatus | text                                 |
      | id01 |     4 | 00002-2 | Rejected  | Cancel not allowed in Only New phase |
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id02 |     5 | 00002-2 | 912828Q45 | Limit   | DAY     | Sell | 1.0      | 9.0 | 105.0 | Canceled | Canceled  | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |
      | id03 |     6 | 00002-2 | 912828Q45 | Limit   | AtClose | Buy  | 0.0      | 9.0 | 105.0 | Canceled | Canceled  | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |
    And all accumulated orders for 912828Q45 and the open order book are
  # the order book has not changed
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | shownQty | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id01 |     4 | 00002-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 |  2.0 | 106.0 | 0.0     | NaN    |  2.0      | 0.0    | NaN   |
    And the close accumulating order book for 912828Q45 is empty
    And the continuous accumulating order book for 912828Q45 is empty

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif     | side | shownQty | qty  | price |
      | id01 | 912828Q45 |     7 | 00003-0 | Limit   | AtOpen  | Sell |      0.0 | 13.0 | 107.0 |
      | id02 | 912828Q45 |     8 | 00003-0 | Limit   | AtOpen  | Buy  |      0.0 | 14.0 | 106.0 |
      | id03 | 912828Q45 |     9 | 00003-0 | Limit   | AtOpen  | Sell |      0.0 |  7.0 | 105.0 |
      | id04 | 912828Q45 |    10 | 00003-0 | Limit   | AtOpen  | Buy  |      0.0 |  4.0 | 104.0 |
      | id05 | 912828Q45 |    11 | 00003-0 | Limit   | AtOpen  | Sell |      0.0 | 11.0 | 103.0 |
      | id06 | 912828Q45 |    12 | 00003-0 | Limit   | AtOpen  | Buy  |      0.0 | 16.0 | 102.0 |
      | id11 | 912828Q45 |    13 | 00003-0 | Limit   | DAY     | Sell |      5.0 | 15.0 | 107.0 |
      | id12 | 912828Q45 |    14 | 00003-0 | Limit   | DAY     | Sell |      3.0 | 11.0 | 105.0 |
      | id13 | 912828Q45 |    15 | 00003-0 | Limit   | DAY     | Buy  |      3.0 | 19.0 | 104.0 |
      | id14 | 912828Q45 |    16 | 00003-0 | Limit   | DAY     | Sell |      3.0 |  5.0 | 103.0 |
      | id15 | 912828Q45 |    17 | 00003-0 | Limit   | DAY     | Buy  |      3.0 |  3.0 | 102.0 |
      | id16 | 912828Q45 |    18 | 00003-0 | Limit   | DAY     | Sell |      3.0 | 10.0 | 101.0 |
      | id17 | 912828Q45 |    19 | 00003-0 | Limit   | DAY     | Buy  |      3.0 | 20.0 | 100.0 |
      | id03 | 912828Q45 |    20 | 00003-0 | Limit   | AtClose | Buy  |      0.0 |  2.0 | 106.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     7 | 00003-0 | 912828Q45 | Limit   | AtOpen  | Sell |      0.0 | 13.0 | 107.0 | New      | New       | 0.0     | NaN    | 13.0      | 0.0    | NaN   |      |
      | id02 |     8 | 00003-0 | 912828Q45 | Limit   | AtOpen  | Buy  |      0.0 | 14.0 | 106.0 | New      | New       | 0.0     | NaN    | 14.0      | 0.0    | NaN   |      |
      | id03 |     9 | 00003-0 | 912828Q45 | Limit   | AtOpen  | Sell |      0.0 |  7.0 | 105.0 | New      | New       | 0.0     | NaN    |  7.0      | 0.0    | NaN   |      |
      | id04 |    10 | 00003-0 | 912828Q45 | Limit   | AtOpen  | Buy  |      0.0 |  4.0 | 104.0 | New      | New       | 0.0     | NaN    |  4.0      | 0.0    | NaN   |      |
      | id05 |    11 | 00003-0 | 912828Q45 | Limit   | AtOpen  | Sell |      0.0 | 11.0 | 103.0 | New      | New       | 0.0     | NaN    | 11.0      | 0.0    | NaN   |      |
      | id06 |    12 | 00003-0 | 912828Q45 | Limit   | AtOpen  | Buy  |      0.0 | 16.0 | 102.0 | New      | New       | 0.0     | NaN    | 16.0      | 0.0    | NaN   |      |
      | id11 |    13 | 00003-0 | 912828Q45 | Limit   | DAY     | Sell |      5.0 | 15.0 | 107.0 | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id12 |    14 | 00003-0 | 912828Q45 | Limit   | DAY     | Sell |      3.0 | 11.0 | 105.0 | New      | New       | 0.0     | NaN    | 11.0      | 0.0    | NaN   |      |
      | id13 |    15 | 00003-0 | 912828Q45 | Limit   | DAY     | Buy  |      3.0 | 19.0 | 104.0 | New      | New       | 0.0     | NaN    | 19.0      | 0.0    | NaN   |      |
      | id14 |    16 | 00003-0 | 912828Q45 | Limit   | DAY     | Sell |      3.0 |  5.0 | 103.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id15 |    17 | 00003-0 | 912828Q45 | Limit   | DAY     | Buy  |      3.0 |  3.0 | 102.0 | New      | New       | 0.0     | NaN    |  3.0      | 0.0    | NaN   |      |
      | id16 |    18 | 00003-0 | 912828Q45 | Limit   | DAY     | Sell |      3.0 | 10.0 | 101.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id17 |    19 | 00003-0 | 912828Q45 | Limit   | DAY     | Buy  |      3.0 | 20.0 | 100.0 | New      | New       | 0.0     | NaN    | 20.0      | 0.0    | NaN   |      |
      | id03 |    20 | 00003-0 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 |  2.0 | 106.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
    And all accumulated orders for 912828Q45 and the open order book are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id01 |     7 | 00003-0 | 912828Q45 | Limit   | AtOpen | Sell | 13.0 | 107.0 | 0.0     | NaN    | 13.0      | 0.0    | NaN   |
      | id01 |     4 | 00002-0 | 912828Q45 | Limit   | AtOpen | Buy  |  2.0 | 106.0 | 0.0     | NaN    |  2.0      | 0.0    | NaN   |
      | id02 |     8 | 00003-0 | 912828Q45 | Limit   | AtOpen | Buy  | 14.0 | 106.0 | 0.0     | NaN    | 14.0      | 0.0    | NaN   |
      | id03 |     9 | 00003-0 | 912828Q45 | Limit   | AtOpen | Sell |  7.0 | 105.0 | 0.0     | NaN    |  7.0      | 0.0    | NaN   |
      | id04 |    10 | 00003-0 | 912828Q45 | Limit   | AtOpen | Buy  |  4.0 | 104.0 | 0.0     | NaN    |  4.0      | 0.0    | NaN   |
      | id05 |    11 | 00003-0 | 912828Q45 | Limit   | AtOpen | Sell | 11.0 | 103.0 | 0.0     | NaN    | 11.0      | 0.0    | NaN   |
      | id06 |    12 | 00003-0 | 912828Q45 | Limit   | AtOpen | Buy  | 16.0 | 102.0 | 0.0     | NaN    | 16.0      | 0.0    | NaN   |
    And all accumulated orders for 912828Q45 and the close order book are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id03 |    20 | 00003-0 | 912828Q45 | Limit   | AtClose | Buy  | 2.0  | 106.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
    And all accumulated orders for 912828Q45 and the continuous order book are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | shownQty | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id11 |    13 | 00003-0 | 912828Q45 | Limit   | DAY    | Sell |      5.0 | 15.0 | 107.0 | 0.0     | NaN    | 15.0      | 0.0    | NaN   |
      | id12 |    14 | 00003-0 | 912828Q45 | Limit   | DAY    | Sell |      3.0 | 11.0 | 105.0 | 0.0     | NaN    | 11.0      | 0.0    | NaN   |
      | id13 |    15 | 00003-0 | 912828Q45 | Limit   | DAY    | Buy  |      3.0 | 19.0 | 104.0 | 0.0     | NaN    | 19.0      | 0.0    | NaN   |
      | id14 |    16 | 00003-0 | 912828Q45 | Limit   | DAY    | Sell |      3.0 |  5.0 | 103.0 | 0.0     | NaN    |  5.0      | 0.0    | NaN   |
      | id15 |    17 | 00003-0 | 912828Q45 | Limit   | DAY    | Buy  |      3.0 |  3.0 | 102.0 | 0.0     | NaN    |  3.0      | 0.0    | NaN   |
      | id16 |    18 | 00003-0 | 912828Q45 | Limit   | DAY    | Sell |      3.0 | 10.0 | 101.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
      | id17 |    19 | 00003-0 | 912828Q45 | Limit   | DAY    | Buy  |      3.0 | 20.0 | 100.0 | 0.0     | NaN    | 20.0      | 0.0    | NaN   |

# AuctionOrderBook.auction() is an atomic operation that clears the bid/offer Size and bid/offer Orders
# In order to check the bid/offer Size we send an imbalance timer event
    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |     0.0 |       0.0 |         0.0 |          72.0 |     0.0 |     0.0 | None        |
      | 107.0 |     0.0 |      28.0 |         0.0 |          72.0 |     0.0 |    72.0 | Sell        |
      | 106.0 |    16.0 |       0.0 |        16.0 |          44.0 |    16.0 |    28.0 | Sell        |
      | 105.0 |     0.0 |      18.0 |        16.0 |          44.0 |    16.0 |    28.0 | Sell        |
      | 104.0 |    23.0 |       0.0 |        39.0 |          26.0 |    26.0 |    13.0 | Buy         |
      | 103.0 |     0.0 |      16.0 |        39.0 |          26.0 |    26.0 |    13.0 | Buy         |
      | 102.0 |    19.0 |       0.0 |        58.0 |          10.0 |    10.0 |    48.0 | Buy         |
      | 101.0 |     0.0 |      10.0 |        58.0 |          10.0 |    10.0 |    48.0 | Buy         |
      | 100.0 |    20.0 |       0.0 |        78.0 |           0.0 |     0.0 |    78.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    26.0 |    13.0 | Buy  |

# Auction time
    Given the open order book receives an auction timer event
    And the continuous order book receives a matching timer event
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | shownQty | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id01 |     4 | 00002-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 |  2.0 | 106.0 | Trade    | Filled          | 2.0     | 104.0  | 0.0       | 2.0    | 104.0 |                     |
      | id02 |     8 | 00003-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 | 14.0 | 106.0 | Trade    | Filled          | 14.0    | 104.0  | 0.0       | 14.0   | 104.0 |                     |
      | id04 |    10 | 00003-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 |  4.0 | 104.0 | Trade    | Filled          | 4.0     | 104.0  | 0.0       | 4.0    | 104.0 |                     |
      | id13 |    15 | 00003-0 | 912828Q45 | Limit   | DAY    | Buy  |      3.0 | 19.0 | 104.0 | Trade    | PartiallyFilled | 6.0     | 104.0  | 13.0      | 6.0    | 104.0 |                     |
      | id06 |    12 | 00003-0 | 912828Q45 | Limit   | AtOpen | Buy  |      0.0 | 16.0 | 102.0 | Canceled | Canceled        | 0.0     | NaN    | 16.0      | 0.0    | NaN   | No match in auction |
      | id16 |    18 | 00003-0 | 912828Q45 | Limit   | DAY    | Sell |      3.0 | 10.0 | 101.0 | Trade    | Filled          | 10.0    | 104.0  | 0.0       | 10.0   | 104.0 |                     |
      | id05 |    11 | 00003-0 | 912828Q45 | Limit   | AtOpen | Sell |      0.0 | 11.0 | 103.0 | Trade    | Filled          | 11.0    | 104.0  | 0.0       | 11.0   | 104.0 |                     |
      | id14 |    16 | 00003-0 | 912828Q45 | Limit   | DAY    | Sell |      3.0 |  5.0 | 103.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id03 |     9 | 00003-0 | 912828Q45 | Limit   | AtOpen | Sell |      0.0 |  7.0 | 105.0 | Canceled | Canceled        | 0.0     | NaN    | 7.0       | 0.0    | NaN   | No match in auction |
      | id01 |     7 | 00003-0 | 912828Q45 | Limit   | AtOpen | Sell |      0.0 | 13.0 | 107.0 | Canceled | Canceled        | 0.0     | NaN    | 13.0      | 0.0    | NaN   | No match in auction |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    26.0 |    13.0 | Buy  |
    And the open accumulating order book for 912828Q45 is empty
    And the continuous accumulating order book for 912828Q45 is empty
    And all accumulated orders for 912828Q45 and the close order book are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id03 |    20 | 00003-0 | 912828Q45 | Limit   | AtClose | Buy  | 2.0  | 106.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
    And all continuous orders for 912828Q45 are
      | uid  | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id11 |    13 | 00003-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 15.0 | 107.0 | 0.0     | NaN    | 15.0      | 0.0    | NaN   |
      | id12 |    14 | 00003-0 | 912828Q45 | Limit   | DAY | Sell | 3.0      | 11.0 | 105.0 | 0.0     | NaN    | 11.0      | 0.0    | NaN   |
      | id13 |    15 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 19.0 | 104.0 | 0.0     | NaN    | 13.0      | 6.0    | 104.0 |
      | id15 |    17 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      |  3.0 | 102.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id17 |    19 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 20.0 | 100.0 | 0.0     | NaN    | 20.0      | 0.0    | NaN   |
  # double check the cumulated leaves and shown
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 104.0 and leaves 13.0 and shown 3.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id13 |    15 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 19.0 | 104.0 | 0.0     | NaN    | 13.0      | 6.0    | 104.0 |

# Contunuous executions
    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif     | side | shownQty | qty  | price |
      | id09 | 912828Q45 |    21 | 00004-0 | Limit   | DAY     | Sell |     10.0 | 25.0 | 103.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id09 |    21 | 00004-0 | 912828Q45 | Limit   | DAY     | Sell |     10.0 | 25.0 | 103.0 | New      | New             | 0.0     | NaN    | 25.0      | 0.0    | NaN   |      |
      | id13 |    15 | 00003-0 | 912828Q45 | Limit   | DAY     | Buy  |      3.0 | 19.0 | 104.0 | Trade    | Filled          | 13.0    | 104.0  | 0.0       | 19.0   | 104.0 |      |
      | id09 |    21 | 00004-0 | 912828Q45 | Limit   | DAY     | Sell |     10.0 | 25.0 | 103.0 | Trade    | PartiallyFilled | 13.0    | 104.0  | 12.0      | 13.0   | 104.0 |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty | price | ordType |
      |    13 | 00003-1 |      5.0 | 9.0 | 104.0 | Limit   |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id11 |    13 | 00003-1 | 912828Q45 | Limit   | DAY     | Sell |      5.0 | 9.0  | 104.0 | Replaced | Replaced  | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 | ask2  | askQ2 |
      | 3.0   | 100.0 | 3.0   | 102.0 | 103.0 | 10.0  | 104.0 | 5.0   | 105.0 | 3.0   |
    And all continuous orders for 912828Q45 are
      | uid  | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id12 |    14 | 00003-0 | 912828Q45 | Limit   | DAY | Sell | 3.0      | 11.0 | 105.0 | 0.0     | NaN    | 11.0      | 0.0    | NaN   |
      | id11 |    13 | 00003-1 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 9.0  | 104.0 | 0.0     | NaN    | 9.0       | 0.0    | NaN   |
      | id09 |    21 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 10.0     | 25.0 | 103.0 | 13.0    | 104.0  | 12.0      | 13.0   | 104.0 |
      | id15 |    17 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      |  3.0 | 102.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id17 |    19 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      | 20.0 | 100.0 | 0.0     | NaN    | 20.0      | 0.0    | NaN   |

    When a cancel request is received
      | ordId | clOrdId |
      |    19 | 00003-1 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 | ask2  | askQ2 |
      | 3.0   | 102.0 | 103.0 | 10.0  | 104.0 | 5.0   | 105.0 | 3.0   |
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id17 |    19 | 00003-1 | 912828Q45 | Limit   | DAY     | Buy  |      3.0 | 20.0 | 100.0 | Canceled | Canceled  | 0.0     | NaN    | 20.0      | 0.0    | NaN   |      |

# Recap before close auction
    And all continuous orders for 912828Q45 are
      | uid  | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id12 |    14 | 00003-0 | 912828Q45 | Limit   | DAY | Sell | 3.0      | 11.0 | 105.0 | 0.0     | NaN    | 11.0      | 0.0    | NaN   |
      | id11 |    13 | 00003-1 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 9.0  | 104.0 | 0.0     | NaN    | 9.0       | 0.0    | NaN   |
      | id09 |    21 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 10.0     | 25.0 | 103.0 | 13.0    | 104.0  | 12.0      | 13.0   | 104.0 |
      | id15 |    17 | 00003-0 | 912828Q45 | Limit   | DAY | Buy  | 3.0      |  3.0 | 102.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty | price | ordType |
      |    20 | 00003-1 |      0.0 | 5.0 | 104.0 | Limit   |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id03 |    20 | 00003-1 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 | 5.0  | 104.0 | Replaced | Replaced  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
    And all accumulated orders for 912828Q45 and the close order book are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id03 |    20 | 00003-1 | 912828Q45 | Limit   | AtClose | Buy  | 5.0  | 104.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |

# close order book transitions to 'only_new' phase
    Given the close order book receives an only_new timer event

  # all orders are accepted
    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif     | side | shownQty | qty  | price |
      | id02 | 912828Q45 |    22 | 00005-0 | Limit   | DAY     | Sell |      5.0 | 15.0 | 106.0 |
      | id03 | 912828Q45 |    23 | 00005-0 | Limit   | AtClose | Buy  |      0.0 |  2.0 | 106.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id02 |    22 | 00005-0 | 912828Q45 | Limit   | DAY     | Sell |      5.0 | 15.0 | 106.0 | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id03 |    23 | 00005-0 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 |  2.0 | 106.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |

  # only AtClose amend is rejected, the others are executed
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty | price | ordType |
      |    22 | 00005-1 |      1.0 | 9.0 | 105.0 | Limit   |
      |    23 | 00005-1 |      0.0 | 9.0 | 105.0 | Limit   |
    Then all rejections sent back to clients are
      | uid  | ordId | clOrdId | ordStatus | text                                |
      | id03 |    23 | 00005-1 | Rejected  | Amend not allowed in Only New phase |
    And the accumulated orders for 912828Q45 and the close order book filtered by side Buy and price 104.0 are
  # the order book has not changed
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id03 |    20 | 00003-1 | 912828Q45 | Limit   | AtClose | Buy  | 5.0  | 104.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id02 |    22 | 00005-1 | 912828Q45 | Limit   | DAY     | Sell | 1.0      | 9.0 | 105.0 | Replaced | Replaced  | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

  # only AtClose cancel is rejected, the others are executed
    When a cancel request is received
      | ordId | clOrdId |
      |    22 | 00005-2 |
      |    23 | 00005-2 |
    Then all rejections sent back to clients are
      | uid  | ordId | clOrdId | ordStatus | text                                 |
      | id03 |    23 | 00005-2 | Rejected  | Cancel not allowed in Only New phase |
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id02 |    22 | 00005-2 | 912828Q45 | Limit   | DAY     | Sell | 1.0      | 9.0 | 105.0 | Canceled | Canceled  | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |
    And all accumulated orders for 912828Q45 and the close order book are
  # the order book has not changed
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id03 |    23 | 00005-0 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 |  2.0 | 106.0 | 0.0     | NaN    |  2.0      | 0.0    | NaN   |
      | id03 |    20 | 00003-1 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 |  5.0 | 104.0 | 0.0     | NaN    |  5.0      | 0.0    | NaN   |
    And the continuous accumulating order book for 912828Q45 is empty

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif     | side | shownQty | qty  | price |
      | id07 | 912828Q45 |    24 | 00005-0 | Limit   | AtClose | Sell |      0.0 | 15.0 | 107.0 |
      | id08 | 912828Q45 |    25 | 00005-0 | Limit   | AtClose | Sell |      0.0 |  2.0 | 105.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id07 |    24 | 00005-0 | 912828Q45 | Limit   | AtClose | Sell |      0.0 | 15.0 | 107.0 | New      | New             | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id08 |    25 | 00005-0 | 912828Q45 | Limit   | AtClose | Sell |      0.0 |  2.0 | 105.0 | New      | New             | 0.0     | NaN    | 2.0       | 0.0    | NaN   |      |
    And all accumulated orders for 912828Q45 and the close order book are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id07 |    24 | 00005-0 | 912828Q45 | Limit   | AtClose | Sell |      0.0 | 15.0 | 107.0 | 0.0     | NaN    | 15.0      | 0.0    | NaN   |
      | id03 |    23 | 00005-0 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 |  2.0 | 106.0 | 0.0     | NaN    |  2.0      | 0.0    | NaN   |
      | id08 |    25 | 00005-0 | 912828Q45 | Limit   | AtClose | Sell |      0.0 |  2.0 | 105.0 | 0.0     | NaN    |  2.0      | 0.0    | NaN   |
      | id03 |    20 | 00003-1 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 |  5.0 | 104.0 | 0.0     | NaN    |  5.0      | 0.0    | NaN   |

# Close auction
    When the close order book receives an imbalance timer event
    Then the close accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |     0.0 |       0.0 |         0.0 |          49.0 |     0.0 |     0.0 | None        |
      | 107.0 |     0.0 |      15.0 |         0.0 |          49.0 |     0.0 |    49.0 | Sell        |
      | 106.0 |     2.0 |       0.0 |         2.0 |          34.0 |     2.0 |    32.0 | Sell        |
      | 105.0 |     0.0 |      13.0 |         2.0 |          34.0 |     2.0 |    32.0 | Sell        |
      | 104.0 |     5.0 |       9.0 |         7.0 |          21.0 |     7.0 |    14.0 | Sell        |
      | 103.0 |     0.0 |      12.0 |         7.0 |          12.0 |     7.0 |     5.0 | Sell        |
      | 102.0 |     3.0 |       0.0 |        10.0 |           0.0 |     0.0 |    10.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 103.0 |     7.0 |     5.0 | Sell |

# Auction time
    Given the close order book receives an auction timer event
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx  | text                |
      | id03 |    23 | 00005-0 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 |  2.0 | 106.0 | Trade    | Filled          | 2.0     | 103.0  | 0.0       | 2.0    | 103.0  |                     |
      | id03 |    20 | 00003-1 | 912828Q45 | Limit   | AtClose | Buy  |      0.0 |  5.0 | 104.0 | Trade    | Filled          | 5.0     | 103.0  | 0.0       | 5.0    | 103.0  |                     |
      | id15 |    17 | 00003-0 | 912828Q45 | Limit   | DAY     | Buy  |      3.0 |  3.0 | 102.0 | Canceled | Canceled        | 0.0     | NaN    | 3.0       | 0.0    | NaN    | No match in auction |
      | id09 |    21 | 00004-0 | 912828Q45 | Limit   | DAY     | Sell |     10.0 | 25.0 | 103.0 | Trade    | PartiallyFilled | 7.0     | 103.0  | 5.0       | 20.0   | 103.65 |                     |
      | id09 |    21 | 00004-0 | 912828Q45 | Limit   | DAY     | Sell |     10.0 | 25.0 | 103.0 | Canceled | Canceled        | 0.0     | NaN    | 5.0       | 20.0   | 103.65 | No match in auction |
      | id11 |    13 | 00003-1 | 912828Q45 | Limit   | DAY     | Sell |      5.0 |  9.0 | 104.0 | Canceled | Canceled        | 0.0     | NaN    | 9.0       | 0.0    | NaN    | No match in auction |
      | id08 |    25 | 00005-0 | 912828Q45 | Limit   | AtClose | Sell |      0.0 |  2.0 | 105.0 | Canceled | Canceled        | 0.0     | NaN    | 2.0       | 0.0    | NaN    | No match in auction |
      | id12 |    14 | 00003-0 | 912828Q45 | Limit   | DAY     | Sell |      3.0 | 11.0 | 105.0 | Canceled | Canceled        | 0.0     | NaN    | 11.0      | 0.0    | NaN    | No match in auction |
      | id07 |    24 | 00005-0 | 912828Q45 | Limit   | AtClose | Sell |      0.0 | 15.0 | 107.0 | Canceled | Canceled        | 0.0     | NaN    | 15.0      | 0.0    | NaN    | No match in auction |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 103.0 |     7.0 |     5.0 | Sell |
    And the continuous accumulating order book for 912828Q45 is empty
    And the close accumulating order book for 912828Q45 is empty

    And a market data snapshot for 912828Q45 is sent to subscribers
  # the final empty snapshot
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | NaN   | 0.0   |

