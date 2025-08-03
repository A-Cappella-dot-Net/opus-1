Feature: Cembalo - Auction

  Background:
    Given the set of available instruments is
      | secId     | minQty | minQtyIncrement | minPriceIncrement | ordering | maxLevels |
      | 912828Q45 | 1.0    | 1.0             | 0.0078125         | 1        | 20        |
    And all books are initialized in open matching state
    And exchange starts with no active orders


  Scenario: Auction Corner case: empty order book

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 is empty
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      |   NaN |     0.0 |     0.0 | None |

    When the open order book receives an auction timer event
    Then no execution reports are sent


  Scenario: Auction Corner case: one sided market

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif    | side | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | AtOpen | Buy  | 10.0 | 102.0 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | 102.0 |    10.0 |       0.0 |        10.0 |           0.0 |     0.0 |    10.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      |   NaN |     0.0 |     0.0 | None |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price 102.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif    | side | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |

    When the open order book receives an auction timer event
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |


  Scenario: Auction Corner case: non overlapping bid/offer orders

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif    | side | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | AtOpen | Buy  | 10.0 | 102.0 |
      | id2 | 912828Q45 |     2 | 00001-0 | Limit   | AtOpen | Sell | 10.0 | 103.0 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 10.0 | 103.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | 103.0 |     0.0 |      10.0 |         0.0 |          10.0 |     0.0 |    10.0 | Sell        |
      | 102.0 |    10.0 |       0.0 |        10.0 |           0.0 |     0.0 |    10.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      |   NaN |     0.0 |     0.0 | None |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price 102.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif    | side | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |

    When the open order book receives an auction timer event
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 10.0 | 103.0 | Canceled | Canceled  | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |


  Scenario: Auction - single max value for matched; surplus on BUY side
  Auction price can only be 104
  Surplus on Buy side => Buys will remain unfilled

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif    | side | qty  | price |
      | id01 | 912828Q45 |     1 | 00001-0 | Market  | AtOpen | Buy  | 12.0 |   NaN |
      | id02 | 912828Q45 |     2 | 00001-0 | Limit   | AtOpen | Sell | 15.0 | 106.0 |
      | id03 | 912828Q45 |     3 | 00001-0 | Limit   | AtOpen | Buy  |  2.0 | 105.0 |
      | id04 | 912828Q45 |     4 | 00001-0 | Limit   | AtOpen | Sell | 12.0 | 105.0 |
      | id05 | 912828Q45 |     5 | 00001-0 | Limit   | AtOpen | Buy  |  4.0 | 104.0 |
      | id06 | 912828Q45 |     6 | 00001-0 | Limit   | AtOpen | Sell |  1.0 | 104.0 |
      | id07 | 912828Q45 |     7 | 00001-0 | Limit   | AtOpen | Buy  |  1.0 | 103.0 |
      | id08 | 912828Q45 |     8 | 00001-0 | Limit   | AtOpen | Sell |  5.0 | 103.0 |
      | id09 | 912828Q45 |     9 | 00001-0 | Limit   | AtOpen | Buy  | 10.0 | 102.0 |
      | id10 | 912828Q45 |    10 | 00001-0 | Limit   | AtOpen | Sell |  5.0 | 102.0 |
      | id11 | 912828Q45 |    11 | 00001-0 | Limit   | AtOpen | Buy  | 10.0 | 101.0 |
      | id12 | 912828Q45 |    12 | 00001-0 | Market  | AtOpen | Sell |  5.0 |   NaN |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 12.0 |   NaN | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 15.0 | 106.0 | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  2.0 | 105.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 12.0 | 105.0 | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  4.0 | 104.0 | New      | New       | 0.0     | NaN    |  4.0      | 0.0    | NaN   |      |
      | id06 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  1.0 | 104.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id07 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  1.0 | 103.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id08 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  5.0 | 103.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id09 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id10 |    10 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  5.0 | 102.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id11 |    11 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 101.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |  5.0 |   NaN | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

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
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 12.0 |   NaN | Trade    | Filled          | 12.0    | 104.0  | 0.0       | 12.0   | 104.0 |                     |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 2.0  | 105.0 | Trade    | Filled          | 2.0     | 104.0  | 0.0       | 2.0    | 104.0 |                     |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 4.0  | 104.0 | Trade    | PartiallyFilled | 2.0     | 104.0  | 2.0       | 2.0    | 104.0 |                     |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 4.0  | 104.0 | Canceled | Canceled        | 0.0     | NaN    | 2.0       | 2.0    | 104.0 | No match in auction |
      | id07 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 1.0  | 103.0 | Canceled | Canceled        | 0.0     | NaN    | 1.0       | 0.0    | NaN   | No match in auction |
      | id09 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 102.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id11 |    11 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 101.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell | 5.0  |   NaN | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id10 |    10 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 5.0  | 102.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id08 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 5.0  | 103.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id06 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 1.0  | 104.0 | Trade    | Filled          | 1.0     | 104.0  | 0.0       | 1.0    | 104.0 |                     |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 12.0 | 105.0 | Canceled | Canceled        | 0.0     | NaN    | 12.0      | 0.0    | NaN   | No match in auction |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 15.0 | 106.0 | Canceled | Canceled        | 0.0     | NaN    | 15.0      | 0.0    | NaN   | No match in auction |


  Scenario: Auction - same max value for matched; same min value for surplus; surplus side = Buy => auction price must be 104.0
  Auction price can be either 104 or 103
  Some Buys will not fill:
  if price = 104 then unfilled were on the wrong side of the imbalance
  if price = 103 then how come I was not filled? my price was better!

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif    | side | qty  | price |
      | id01 | 912828Q45 |     1 | 00001-0 | Market  | AtOpen | Buy  | 12.0 |   0.0 |
      | id02 | 912828Q45 |     2 | 00001-0 | Limit   | AtOpen | Sell | 15.0 | 106.0 |
      | id03 | 912828Q45 |     3 | 00001-0 | Limit   | AtOpen | Buy  |  2.0 | 105.0 |
      | id04 | 912828Q45 |     4 | 00001-0 | Limit   | AtOpen | Sell | 12.0 | 105.0 |
      | id05 | 912828Q45 |     5 | 00001-0 | Limit   | AtOpen | Buy  |  5.0 | 104.0 |
      | id08 | 912828Q45 |     6 | 00001-0 | Limit   | AtOpen | Sell |  5.0 | 103.0 |
      | id09 | 912828Q45 |     7 | 00001-0 | Limit   | AtOpen | Buy  | 10.0 | 102.0 |
      | id10 | 912828Q45 |     8 | 00001-0 | Limit   | AtOpen | Sell |  5.0 | 102.0 |
      | id11 | 912828Q45 |     9 | 00001-0 | Limit   | AtOpen | Buy  | 10.0 | 101.0 |
      | id12 | 912828Q45 |    10 | 00001-0 | Market  | AtOpen | Sell |  5.0 |   0.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 12.0 |   0.0 | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 15.0 | 106.0 | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  2.0 | 105.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 12.0 | 105.0 | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  5.0 | 104.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id08 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  5.0 | 103.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id09 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id10 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  5.0 | 102.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id11 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 101.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id12 |    10 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |  5.0 |   0.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |    12.0 |       0.0 |        12.0 |          42.0 |    12.0 |    30.0 | Sell        |
      | 106.0 |     0.0 |      15.0 |        12.0 |          42.0 |    12.0 |    30.0 | Sell        |
      | 105.0 |     2.0 |      12.0 |        14.0 |          27.0 |    14.0 |    13.0 | Sell        |
      | 104.0 |     5.0 |       0.0 |        19.0 |          15.0 |    15.0 |     4.0 | Buy         |
      | 103.0 |     0.0 |       5.0 |        19.0 |          15.0 |    15.0 |     4.0 | Buy         |
      | 102.0 |    10.0 |       5.0 |        29.0 |          10.0 |    10.0 |    19.0 | Buy         |
      | 101.0 |    10.0 |       0.0 |        39.0 |           5.0 |     5.0 |    34.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        39.0 |           5.0 |     5.0 |    34.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    15.0 |     4.0 | Buy  |
    When the open order book receives an auction timer event
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 12.0 |   0.0 | Trade    | Filled          | 12.0    | 104.0  | 0.0       | 12.0   | 104.0 |                     |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 2.0  | 105.0 | Trade    | Filled          | 2.0     | 104.0  | 0.0       | 2.0    | 104.0 |                     |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 5.0  | 104.0 | Trade    | PartiallyFilled | 1.0     | 104.0  | 4.0       | 1.0    | 104.0 |                     |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 5.0  | 104.0 | Canceled | Canceled        | 0.0     | NaN    | 4.0       | 1.0    | 104.0 | No match in auction |
      | id09 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 102.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id11 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 101.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id12 |    10 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell | 5.0  |   0.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id10 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 5.0  | 102.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id08 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 5.0  | 103.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 12.0 | 105.0 | Canceled | Canceled        | 0.0     | NaN    | 12.0      | 0.0    | NaN   | No match in auction |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 15.0 | 106.0 | Canceled | Canceled        | 0.0     | NaN    | 15.0      | 0.0    | NaN   | No match in auction |


  Scenario: Auction - same max value for matched; same 0 value for surplus; surplus side = None => no hurt feelings (value from tie)
  Auction price can be 103 or 104
  Nothing will remain un-filled, so need another criterion to choose the auction price, e.g., mid if available, consistent/antagonic with sector, etc.
  Indifferent, no hurt feelings

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif    | side | qty  | price |
      | id01 | 912828Q45 |     1 | 00001-0 | Market  | AtOpen | Buy  |  8.0 |   0.0 |
      | id02 | 912828Q45 |     2 | 00001-0 | Limit   | AtOpen | Sell | 15.0 | 106.0 |
      | id03 | 912828Q45 |     3 | 00001-0 | Limit   | AtOpen | Buy  |  2.0 | 105.0 |
      | id04 | 912828Q45 |     4 | 00001-0 | Limit   | AtOpen | Sell | 12.0 | 105.0 |
      | id05 | 912828Q45 |     5 | 00001-0 | Limit   | AtOpen | Buy  |  5.0 | 104.0 |
      | id08 | 912828Q45 |     6 | 00001-0 | Limit   | AtOpen | Sell |  5.0 | 103.0 |
      | id09 | 912828Q45 |     7 | 00001-0 | Limit   | AtOpen | Buy  | 10.0 | 102.0 |
      | id10 | 912828Q45 |     8 | 00001-0 | Limit   | AtOpen | Sell |  5.0 | 102.0 |
      | id11 | 912828Q45 |     9 | 00001-0 | Limit   | AtOpen | Buy  | 10.0 | 101.0 |
      | id12 | 912828Q45 |    10 | 00001-0 | Market  | AtOpen | Sell |  5.0 |   0.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  |  8.0 |   0.0 | New      | New       | 0.0     | NaN    |  8.0      | 0.0    | NaN   |      |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 15.0 | 106.0 | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  2.0 | 105.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 12.0 | 105.0 | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  5.0 | 104.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id08 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  5.0 | 103.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id09 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id10 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  5.0 | 102.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id11 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 101.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id12 |    10 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |  5.0 |   0.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |     8.0 |       0.0 |         8.0 |          42.0 |     8.0 |    34.0 | Sell        |
      | 106.0 |     0.0 |      15.0 |         8.0 |          42.0 |     8.0 |    34.0 | Sell        |
      | 105.0 |     2.0 |      12.0 |        10.0 |          27.0 |    10.0 |    17.0 | Sell        |
      | 104.0 |     5.0 |       0.0 |        15.0 |          15.0 |    15.0 |     0.0 | None        |
      | 103.0 |     0.0 |       5.0 |        15.0 |          15.0 |    15.0 |     0.0 | None        |
      | 102.0 |    10.0 |       5.0 |        25.0 |          10.0 |    10.0 |    15.0 | Buy         |
      | 101.0 |    10.0 |       0.0 |        35.0 |           5.0 |     5.0 |    30.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        35.0 |           5.0 |     5.0 |    30.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    15.0 |     0.0 | None |

    When the open order book receives an auction timer event
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 8.0  |   0.0 | Trade    | Filled          | 8.0     | 104.0  | 0.0       | 8.0    | 104.0 |                     |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 2.0  | 105.0 | Trade    | Filled          | 2.0     | 104.0  | 0.0       | 2.0    | 104.0 |                     |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 5.0  | 104.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id09 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 102.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id11 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 101.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id12 |    10 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell | 5.0  |   0.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id10 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 5.0  | 102.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id08 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 5.0  | 103.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 12.0 | 105.0 | Canceled | Canceled        | 0.0     | NaN    | 12.0      | 0.0    | NaN   | No match in auction |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 15.0 | 106.0 | Canceled | Canceled        | 0.0     | NaN    | 15.0      | 0.0    | NaN   | No match in auction |


  Scenario: Auction - same max value for matched; same min value for surplus; different surplus sides => indifferent
  Auction price can be either 104 or 103
  1 Sell @ 104 or 1 Buy @ 103 will remain unfilled, but that is due to being on the wrong side of the imbalance
  Indifferent, some hurt feelings

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif    | side | qty  | price |
      | id01 | 912828Q45 |     1 | 00001-0 | Market  | AtOpen | Buy  |  8.0 |   0.0 |
      | id02 | 912828Q45 |     2 | 00001-0 | Limit   | AtOpen | Sell | 15.0 | 106.0 |
      | id03 | 912828Q45 |     3 | 00001-0 | Limit   | AtOpen | Buy  |  2.0 | 105.0 |
      | id04 | 912828Q45 |     4 | 00001-0 | Limit   | AtOpen | Sell | 11.0 | 105.0 |
      | id05 | 912828Q45 |     5 | 00001-0 | Limit   | AtOpen | Buy  |  5.0 | 104.0 |
      | id06 | 912828Q45 |     6 | 00001-0 | Limit   | AtOpen | Sell |  1.0 | 104.0 |
      | id07 | 912828Q45 |     7 | 00001-0 | Limit   | AtOpen | Buy  |  1.0 | 103.0 |
      | id08 | 912828Q45 |     8 | 00001-0 | Limit   | AtOpen | Sell |  5.0 | 103.0 |
      | id09 | 912828Q45 |     9 | 00001-0 | Limit   | AtOpen | Buy  |  9.0 | 102.0 |
      | id10 | 912828Q45 |    10 | 00001-0 | Limit   | AtOpen | Sell |  5.0 | 102.0 |
      | id11 | 912828Q45 |    11 | 00001-0 | Limit   | AtOpen | Buy  | 10.0 | 101.0 |
      | id12 | 912828Q45 |    12 | 00001-0 | Market  | AtOpen | Sell |  5.0 |   0.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  |  8.0 |   0.0 | New      | New       | 0.0     | NaN    |  8.0      | 0.0    | NaN   |      |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 15.0 | 106.0 | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  2.0 | 105.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 11.0 | 105.0 | New      | New       | 0.0     | NaN    | 11.0      | 0.0    | NaN   |      |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  5.0 | 104.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id06 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  1.0 | 104.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id07 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  1.0 | 103.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id08 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  5.0 | 103.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id09 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  9.0 | 102.0 | New      | New       | 0.0     | NaN    |  9.0      | 0.0    | NaN   |      |
      | id10 |    10 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  5.0 | 102.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id11 |    11 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 101.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |  5.0 |   0.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |     8.0 |       0.0 |         8.0 |          42.0 |     8.0 |    34.0 | Sell        |
      | 106.0 |     0.0 |      15.0 |         8.0 |          42.0 |     8.0 |    34.0 | Sell        |
      | 105.0 |     2.0 |      11.0 |        10.0 |          27.0 |    10.0 |    17.0 | Sell        |
      | 104.0 |     5.0 |       1.0 |        15.0 |          16.0 |    15.0 |     1.0 | Sell        |
      | 103.0 |     1.0 |       5.0 |        16.0 |          15.0 |    15.0 |     1.0 | Buy         |
      | 102.0 |     9.0 |       5.0 |        25.0 |          10.0 |    10.0 |    15.0 | Buy         |
      | 101.0 |    10.0 |       0.0 |        35.0 |           5.0 |     5.0 |    30.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        35.0 |           5.0 |     5.0 |    30.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    15.0 |     1.0 | Sell |

    When the open order book receives an auction timer event
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 8.0  |   0.0 | Trade    | Filled          | 8.0     | 104.0  | 0.0       | 8.0    | 104.0 |                     |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 2.0  | 105.0 | Trade    | Filled          | 2.0     | 104.0  | 0.0       | 2.0    | 104.0 |                     |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 5.0  | 104.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id07 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 1.0  | 103.0 | Canceled | Canceled        | 0.0     | NaN    | 1.0       | 0.0    | NaN   | No match in auction |
      | id09 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 9.0  | 102.0 | Canceled | Canceled        | 0.0     | NaN    | 9.0       | 0.0    | NaN   | No match in auction |
      | id11 |    11 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 101.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell | 5.0  |   0.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id10 |    10 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 5.0  | 102.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id08 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 5.0  | 103.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id06 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 1.0  | 104.0 | Canceled | Canceled        | 0.0     | NaN    | 1.0       | 0.0    | NaN   | No match in auction |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 11.0 | 105.0 | Canceled | Canceled        | 0.0     | NaN    | 11.0      | 0.0    | NaN   | No match in auction |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 15.0 | 106.0 | Canceled | Canceled        | 0.0     | NaN    | 15.0      | 0.0    | NaN   | No match in auction |


  Scenario: Auction - same max value for matched; different min value for surplus
  Auction price can be 104 or 103
  1 Buy @ 103 or 2 Sell @ 104 would remain unfilled, consistent to being on the wrong side of the imbalance
  Would like to hurt as few feelings as possible => pick the price with min surplus, i.e., 103

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif    | side | qty  | price |
      | id01 | 912828Q45 |     1 | 00001-0 | Market  | AtOpen | Buy  |  8.0 |   0.0 |
      | id02 | 912828Q45 |     2 | 00001-0 | Limit   | AtOpen | Sell | 15.0 | 106.0 |
      | id03 | 912828Q45 |     3 | 00001-0 | Limit   | AtOpen | Buy  |  2.0 | 105.0 |
      | id04 | 912828Q45 |     4 | 00001-0 | Limit   | AtOpen | Sell | 10.0 | 105.0 |
      | id05 | 912828Q45 |     5 | 00001-0 | Limit   | AtOpen | Buy  |  5.0 | 104.0 |
      | id06 | 912828Q45 |     6 | 00001-0 | Limit   | AtOpen | Sell |  2.0 | 104.0 |
      | id07 | 912828Q45 |     7 | 00001-0 | Limit   | AtOpen | Buy  |  1.0 | 103.0 |
      | id08 | 912828Q45 |     8 | 00001-0 | Limit   | AtOpen | Sell |  5.0 | 103.0 |
      | id09 | 912828Q45 |     9 | 00001-0 | Limit   | AtOpen | Buy  |  9.0 | 102.0 |
      | id10 | 912828Q45 |    10 | 00001-0 | Limit   | AtOpen | Sell |  5.0 | 102.0 |
      | id11 | 912828Q45 |    11 | 00001-0 | Limit   | AtOpen | Buy  | 10.0 | 101.0 |
      | id12 | 912828Q45 |    12 | 00001-0 | Market  | AtOpen | Sell |  5.0 |   0.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  |  8.0 |   0.0 | New      | New       | 0.0     | NaN    |  8.0      | 0.0    | NaN   |      |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 15.0 | 106.0 | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  2.0 | 105.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 10.0 | 105.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  5.0 | 104.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id06 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  2.0 | 104.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
      | id07 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  1.0 | 103.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id08 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  5.0 | 103.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id09 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  9.0 | 102.0 | New      | New       | 0.0     | NaN    |  9.0      | 0.0    | NaN   |      |
      | id10 |    10 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  5.0 | 102.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id11 |    11 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 101.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |  5.0 |   0.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |     8.0 |       0.0 |         8.0 |          42.0 |     8.0 |    34.0 | Sell        |
      | 106.0 |     0.0 |      15.0 |         8.0 |          42.0 |     8.0 |    34.0 | Sell        |
      | 105.0 |     2.0 |      10.0 |        10.0 |          27.0 |    10.0 |    17.0 | Sell        |
      | 104.0 |     5.0 |       2.0 |        15.0 |          17.0 |    15.0 |     2.0 | Sell        |
      | 103.0 |     1.0 |       5.0 |        16.0 |          15.0 |    15.0 |     1.0 | Buy         |
      | 102.0 |     9.0 |       5.0 |        25.0 |          10.0 |    10.0 |    15.0 | Buy         |
      | 101.0 |    10.0 |       0.0 |        35.0 |           5.0 |     5.0 |    30.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        35.0 |           5.0 |     5.0 |    30.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 103.0 |    15.0 |     1.0 | Buy  |

    When the open order book receives an auction timer event
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 8.0  |   0.0 | Trade    | Filled          | 8.0     | 103.0  | 0.0       | 8.0    | 103.0 |                     |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 2.0  | 105.0 | Trade    | Filled          | 2.0     | 103.0  | 0.0       | 2.0    | 103.0 |                     |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 5.0  | 104.0 | Trade    | Filled          | 5.0     | 103.0  | 0.0       | 5.0    | 103.0 |                     |
      | id07 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 1.0  | 103.0 | Canceled | Canceled        | 0.0     | NaN    | 1.0       | 0.0    | NaN   | No match in auction |
      | id09 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 9.0  | 102.0 | Canceled | Canceled        | 0.0     | NaN    | 9.0       | 0.0    | NaN   | No match in auction |
      | id11 |    11 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 101.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id12 |    12 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell | 5.0  |   0.0 | Trade    | Filled          | 5.0     | 103.0  | 0.0       | 5.0    | 103.0 |                     |
      | id10 |    10 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 5.0  | 102.0 | Trade    | Filled          | 5.0     | 103.0  | 0.0       | 5.0    | 103.0 |                     |
      | id08 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 5.0  | 103.0 | Trade    | Filled          | 5.0     | 103.0  | 0.0       | 5.0    | 103.0 |                     |
      | id06 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 2.0  | 104.0 | Canceled | Canceled        | 0.0     | NaN    | 2.0       | 0.0    | NaN   | No match in auction |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 10.0 | 105.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 15.0 | 106.0 | Canceled | Canceled        | 0.0     | NaN    | 15.0      | 0.0    | NaN   | No match in auction |


  Scenario: Auction - # same max value for matched; different min value for surplus
  Auction price can be 103 or 104
  Surplus on Sell side => Some Sell at either 103 or 104 will not fill
  Auction price must be 103 otherwise seller at 103 will complain:
  my price was better than the auction price and I still did not get filled!

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif    | side | qty  | price |
      | id01 | 912828Q45 |     1 | 00001-0 | Market  | AtOpen | Buy  | 12.0 |   0.0 |
      | id02 | 912828Q45 |     2 | 00001-0 | Limit   | AtOpen | Sell | 15.0 | 106.0 |
      | id03 | 912828Q45 |     3 | 00001-0 | Limit   | AtOpen | Buy  |  2.0 | 105.0 |
      | id04 | 912828Q45 |     4 | 00001-0 | Limit   | AtOpen | Sell | 12.0 | 105.0 |
      | id05 | 912828Q45 |     5 | 00001-0 | Limit   | AtOpen | Buy  |  1.0 | 104.0 |
      | id08 | 912828Q45 |     6 | 00001-0 | Limit   | AtOpen | Sell |  9.0 | 103.0 |
      | id09 | 912828Q45 |     7 | 00001-0 | Limit   | AtOpen | Buy  | 14.0 | 102.0 |
      | id10 | 912828Q45 |     8 | 00001-0 | Limit   | AtOpen | Sell |  5.0 | 102.0 |
      | id11 | 912828Q45 |     9 | 00001-0 | Limit   | AtOpen | Buy  | 10.0 | 101.0 |
      | id12 | 912828Q45 |    10 | 00001-0 | Market  | AtOpen | Sell |  5.0 |   0.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 12.0 |   0.0 | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 15.0 | 106.0 | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  2.0 | 105.0 | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 12.0 | 105.0 | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  1.0 | 104.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id08 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  9.0 | 103.0 | New      | New       | 0.0     | NaN    |  9.0      | 0.0    | NaN   |      |
      | id09 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 14.0 | 102.0 | New      | New       | 0.0     | NaN    | 14.0      | 0.0    | NaN   |      |
      | id10 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  5.0 | 102.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id11 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 101.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id12 |    10 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |  5.0 |   0.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |    12.0 |       0.0 |        12.0 |          46.0 |    12.0 |    34.0 | Sell        |
      | 106.0 |     0.0 |      15.0 |        12.0 |          46.0 |    12.0 |    34.0 | Sell        |
      | 105.0 |     2.0 |      12.0 |        14.0 |          31.0 |    14.0 |    17.0 | Sell        |
      | 104.0 |     1.0 |       0.0 |        15.0 |          19.0 |    15.0 |     4.0 | Sell        |
      | 103.0 |     0.0 |       9.0 |        15.0 |          19.0 |    15.0 |     4.0 | Sell        |
      | 102.0 |    14.0 |       5.0 |        29.0 |          10.0 |    10.0 |    19.0 | Buy         |
      | 101.0 |    10.0 |       0.0 |        39.0 |           5.0 |     5.0 |    34.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        39.0 |           5.0 |     5.0 |    34.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 103.0 |    15.0 |     4.0 | Sell |

    When the open order book receives an auction timer event
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id01 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 12.0 |   0.0 | Trade    | Filled          | 12.0    | 103.0  | 0.0       | 12.0   | 103.0 |                     |
      | id03 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 2.0  | 105.0 | Trade    | Filled          | 2.0     | 103.0  | 0.0       | 2.0    | 103.0 |                     |
      | id05 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 1.0  | 104.0 | Trade    | Filled          | 1.0     | 103.0  | 0.0       | 1.0    | 103.0 |                     |
      | id09 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 14.0 | 102.0 | Canceled | Canceled        | 0.0     | NaN    | 14.0      | 0.0    | NaN   | No match in auction |
      | id11 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 10.0 | 101.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 0.0    | NaN   | No match in auction |
      | id12 |    10 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell | 5.0  |   0.0 | Trade    | Filled          | 5.0     | 103.0  | 0.0       | 5.0    | 103.0 |                     |
      | id10 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 5.0  | 102.0 | Trade    | Filled          | 5.0     | 103.0  | 0.0       | 5.0    | 103.0 |                     |
      | id08 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 9.0  | 103.0 | Trade    | PartiallyFilled | 5.0     | 103.0  | 4.0       | 5.0    | 103.0 |                     |
      | id08 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 9.0  | 103.0 | Canceled | Canceled        | 0.0     | NaN    | 4.0       | 5.0    | 103.0 | No match in auction |
      | id04 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 12.0 | 105.0 | Canceled | Canceled        | 0.0     | NaN    | 12.0      | 0.0    | NaN   | No match in auction |
      | id02 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 15.0 | 106.0 | Canceled | Canceled        | 0.0     | NaN    | 15.0      | 0.0    | NaN   | No match in auction |


  Scenario Outline: Auction - base case for cancel/amend scenarios

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif   | side | qty  | price |
      | id11 | 912828Q45 |     1 | 00001-0 | Market  | <tif> | Buy  | 12.0 |   NaN |
      | id21 | 912828Q45 |     2 | 00001-0 | Limit   | <tif> | Buy  |  5.0 | 104.0 |
      | id22 | 912828Q45 |     3 | 00001-0 | Limit   | <tif> | Sell | 16.0 | 104.0 |
      | id31 | 912828Q45 |     4 | 00001-0 | Limit   | <tif> | Buy  |  8.0 | 103.0 |
      | id32 | 912828Q45 |     5 | 00001-0 | Limit   | <tif> | Sell |  6.0 | 103.0 |
      | id41 | 912828Q45 |     6 | 00001-0 | Market  | <tif> | Sell |  5.0 |   NaN |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif   | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id11 |     1 | 00001-0 | 912828Q45 | Market  | <tif> | Buy  | 12.0 |   NaN | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id21 |     2 | 00001-0 | 912828Q45 | Limit   | <tif> | Buy  |  5.0 | 104.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id22 |     3 | 00001-0 | 912828Q45 | Limit   | <tif> | Sell | 16.0 | 104.0 | New      | New       | 0.0     | NaN    | 16.0      | 0.0    | NaN   |      |
      | id31 |     4 | 00001-0 | 912828Q45 | Limit   | <tif> | Buy  |  8.0 | 103.0 | New      | New       | 0.0     | NaN    |  8.0      | 0.0    | NaN   |      |
      | id32 |     5 | 00001-0 | 912828Q45 | Limit   | <tif> | Sell |  6.0 | 103.0 | New      | New       | 0.0     | NaN    |  6.0      | 0.0    | NaN   |      |
      | id41 |     6 | 00001-0 | 912828Q45 | Market  | <tif> | Sell |  5.0 |   NaN | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

    When the <bookType> order book receives an imbalance timer event
    Then the <bookType> accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |    12.0 |       0.0 |        12.0 |          27.0 |    12.0 |    15.0 | Sell        |
      | 104.0 |     5.0 |      16.0 |        17.0 |          27.0 |    17.0 |    10.0 | Sell        |
      | 103.0 |     8.0 |       6.0 |        25.0 |          11.0 |    11.0 |    14.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        25.0 |           5.0 |     5.0 |    20.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    17.0 |    10.0 | Sell |
    And the accumulated orders for 912828Q45 and the <bookType> order book filtered by side Buy and price 104.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif   | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id21 |     2 | 00001-0 | 912828Q45 | Limit   | <tif> | Buy  | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the accumulated orders for 912828Q45 and the <bookType> order book filtered by side Sell and price -Inf are
      | uid  | ordId | clOrdId | secId     | ordType | tif   | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id41 |     6 | 00001-0 | 912828Q45 | Market  | <tif> | Sell | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |

    When the <bookType> order book receives an auction timer event
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif   | side | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id11 |     1 | 00001-0 | 912828Q45 | Market  | <tif> | Buy  | 12.0 |   NaN | Trade    | Filled          | 12.0    | 104.0  | 0.0       | 12.0   | 104.0 |                     |
      | id21 |     2 | 00001-0 | 912828Q45 | Limit   | <tif> | Buy  | 5.0  | 104.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id31 |     4 | 00001-0 | 912828Q45 | Limit   | <tif> | Buy  | 8.0  | 103.0 | Canceled | Canceled        | 0.0     | NaN    | 8.0       | 0.0    | NaN   | No match in auction |
      | id41 |     6 | 00001-0 | 912828Q45 | Market  | <tif> | Sell | 5.0  |   NaN | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id32 |     5 | 00001-0 | 912828Q45 | Limit   | <tif> | Sell | 6.0  | 103.0 | Trade    | Filled          | 6.0     | 104.0  | 0.0       | 6.0    | 104.0 |                     |
      | id22 |     3 | 00001-0 | 912828Q45 | Limit   | <tif> | Sell | 16.0 | 104.0 | Trade    | PartiallyFilled | 6.0     | 104.0  | 10.0      | 6.0    | 104.0 |                     |
      | id22 |     3 | 00001-0 | 912828Q45 | Limit   | <tif> | Sell | 16.0 | 104.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 6.0    | 104.0 | No match in auction |

    Examples: Relevant Combinations
      | bookType | tif     |
      | open     | AtOpen  |
      | close    | AtClose |


  Scenario: Auction - cancel scenario: market and limit orders are canceled

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif    | side | qty  | price |
      | id11 | 912828Q45 |     1 | 00001-0 | Market  | AtOpen | Buy  |  8.0 |   NaN |
      | id12 | 912828Q45 |     2 | 00001-0 | Market  | AtOpen | Buy  |  4.0 |   NaN |
      | id13 | 912828Q45 |     3 | 00001-0 | Market  | AtOpen | Buy  | 10.0 |   NaN |
      | id21 | 912828Q45 |     4 | 00001-0 | Limit   | AtOpen | Buy  |  5.0 | 104.0 |
      | id22 | 912828Q45 |     5 | 00001-0 | Limit   | AtOpen | Sell | 16.0 | 104.0 |
      | id23 | 912828Q45 |     6 | 00001-0 | Limit   | AtOpen | Sell | 20.0 | 104.0 |
      | id31 | 912828Q45 |     7 | 00001-0 | Limit   | AtOpen | Buy  |  8.0 | 103.0 |
      | id32 | 912828Q45 |     8 | 00001-0 | Limit   | AtOpen | Sell |  6.0 | 103.0 |
      | id41 | 912828Q45 |     9 | 00001-0 | Market  | AtOpen | Sell |  5.0 |   NaN |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id11 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  |  8.0 |   NaN | New      | New       | 0.0     | NaN    |  8.0      | 0.0    | NaN   |      |
      | id12 |     2 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  |  4.0 |   NaN | New      | New       | 0.0     | NaN    |  4.0      | 0.0    | NaN   |      |
      | id13 |     3 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 10.0 |   NaN | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id21 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  5.0 | 104.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id22 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 16.0 | 104.0 | New      | New       | 0.0     | NaN    | 16.0      | 0.0    | NaN   |      |
      | id23 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 20.0 | 104.0 | New      | New       | 0.0     | NaN    | 20.0      | 0.0    | NaN   |      |
      | id31 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  8.0 | 103.0 | New      | New       | 0.0     | NaN    |  8.0      | 0.0    | NaN   |      |
      | id32 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  6.0 | 103.0 | New      | New       | 0.0     | NaN    |  6.0      | 0.0    | NaN   |      |
      | id41 |     9 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |  5.0 |   NaN | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

    When a cancel request is received
      | ordId | clOrdId |
      |     3 | 00001-1 |
      |     6 | 00001-1 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id13 |     3 | 00001-1 | 912828Q45 | Market  | AtOpen | Buy  | 10.0 |   NaN | Canceled | Canceled  | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id23 |     6 | 00001-1 | 912828Q45 | Limit   | AtOpen | Sell | 20.0 | 104.0 | Canceled | Canceled  | 0.0     | NaN    | 20.0      | 0.0    | NaN   |      |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |    12.0 |       0.0 |        12.0 |          27.0 |    12.0 |    15.0 | Sell        |
      | 104.0 |     5.0 |      16.0 |        17.0 |          27.0 |    17.0 |    10.0 | Sell        |
      | 103.0 |     8.0 |       6.0 |        25.0 |          11.0 |    11.0 |    14.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        25.0 |           5.0 |     5.0 |    20.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    17.0 |    10.0 | Sell |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price 104.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id21 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Sell and price -Inf are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id41 |     9 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |

    When the open order book receives an auction timer event
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id11 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 8.0  |   NaN | Trade    | Filled          | 8.0     | 104.0  | 0.0       | 8.0    | 104.0 |                     |
      | id12 |     2 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 4.0  |   NaN | Trade    | Filled          | 4.0     | 104.0  | 0.0       | 4.0    | 104.0 |                     |
      | id21 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 5.0  | 104.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id31 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 8.0  | 103.0 | Canceled | Canceled        | 0.0     | NaN    | 8.0       | 0.0    | NaN   | No match in auction |
      | id41 |     9 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell | 5.0  |   NaN | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id32 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 6.0  | 103.0 | Trade    | Filled          | 6.0     | 104.0  | 0.0       | 6.0    | 104.0 |                     |
      | id22 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 16.0 | 104.0 | Trade    | PartiallyFilled | 6.0     | 104.0  | 10.0      | 6.0    | 104.0 |                     |
      | id22 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 16.0 | 104.0 | Canceled | Canceled        | 0.0     | NaN    | 10.0      | 6.0    | 104.0 | No match in auction |


  Scenario: Auction - amend size scenario: market and limit orders are amended

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif    | side | qty  | price |
      | id11 | 912828Q45 |     1 | 00001-0 | Market  | AtOpen | Buy  |  2.0 |   NaN |
      | id12 | 912828Q45 |     2 | 00001-0 | Market  | AtOpen | Buy  | 10.0 |   NaN |
      | id13 | 912828Q45 |     3 | 00001-0 | Market  | AtOpen | Buy  |  3.0 |   NaN |
      | id21 | 912828Q45 |     4 | 00001-0 | Limit   | AtOpen | Buy  |  5.0 | 104.0 |
      | id22 | 912828Q45 |     5 | 00001-0 | Limit   | AtOpen | Sell |  1.0 | 104.0 |
      | id23 | 912828Q45 |     6 | 00001-0 | Limit   | AtOpen | Sell |  6.0 | 104.0 |
      | id24 | 912828Q45 |     7 | 00001-0 | Limit   | AtOpen | Sell |  8.0 | 104.0 |
      | id31 | 912828Q45 |     8 | 00001-0 | Limit   | AtOpen | Buy  |  8.0 | 103.0 |
      | id32 | 912828Q45 |     9 | 00001-0 | Limit   | AtOpen | Sell |  6.0 | 103.0 |
      | id41 | 912828Q45 |    10 | 00001-0 | Market  | AtOpen | Sell |  5.0 |   NaN |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id11 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  |  2.0 |   NaN | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
      | id12 |     2 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 10.0 |   NaN | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id13 |     3 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  |  3.0 |   NaN | New      | New       | 0.0     | NaN    |  3.0      | 0.0    | NaN   |      |
      | id21 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  5.0 | 104.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id22 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  1.0 | 104.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id23 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  6.0 | 104.0 | New      | New       | 0.0     | NaN    |  6.0      | 0.0    | NaN   |      |
      | id24 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  8.0 | 104.0 | New      | New       | 0.0     | NaN    |  8.0      | 0.0    | NaN   |      |
      | id31 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  8.0 | 103.0 | New      | New       | 0.0     | NaN    |  8.0      | 0.0    | NaN   |      |
      | id32 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  6.0 | 103.0 | New      | New       | 0.0     | NaN    |  6.0      | 0.0    | NaN   |      |
      | id41 |    10 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |  5.0 |   NaN | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

    When a replacement request is received
  # No loss of queue position
      | ordId | clOrdId | qty | price |
      |     2 | 00001-1 | 5.0 |   NaN |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id12 |     2 | 00001-1 | 912828Q45 | Market  | AtOpen | Buy  |  5.0 |   NaN | Replaced | Replaced  | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price Inf are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id11 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
      | id12 |     2 | 00001-1 | 912828Q45 | Market  | AtOpen | Buy  | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id13 |     3 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |

    When a replacement request is received
  # Queue position loss
      | ordId | clOrdId | qty | price |
      |     2 | 00001-2 | 7.0 |   NaN |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id12 |     2 | 00001-2 | 912828Q45 | Market  | AtOpen | Buy  |  7.0 |   NaN | Replaced | Replaced  | 0.0     | NaN    |  7.0      | 0.0    | NaN   |      |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price Inf are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id11 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
      | id13 |     3 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id12 |     2 | 00001-2 | 912828Q45 | Market  | AtOpen | Buy  | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |

    When a replacement request is received
  # No loss of queue position
      | ordId | clOrdId | qty | price |
      |     6 | 00001-1 | 1.0 | 104.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id23 |     6 | 00001-1 | 912828Q45 | Limit   | AtOpen | Sell |  1.0 | 104.0 | Replaced | Replaced  | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Sell and price 104.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id22 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 1.0 | 0.0     | NaN    |  1.0      | 0.0    | NaN   |
      | id23 |     6 | 00001-1 | 912828Q45 | Limit   | AtOpen | Sell | 1.0 | 0.0     | NaN    |  1.0      | 0.0    | NaN   |
      | id24 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 8.0 | 0.0     | NaN    |  8.0      | 0.0    | NaN   |

    When a replacement request is received
  # Queue position loss
      | ordId | clOrdId | qty | price |
      |     6 | 00001-2 | 7.0 | 104.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id23 |     6 | 00001-2 | 912828Q45 | Limit   | AtOpen | Sell |  7.0 | 104.0 | Replaced | Replaced  | 0.0     | NaN    |  7.0      | 0.0    | NaN   |      |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Sell and price 104.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id22 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 1.0 | 0.0     | NaN    | 1.0       | 0.0    | NaN   |
      | id24 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id23 |     6 | 00001-2 | 912828Q45 | Limit   | AtOpen | Sell | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |    12.0 |       0.0 |        12.0 |          27.0 |    12.0 |    15.0 | Sell        |
      | 104.0 |     5.0 |      16.0 |        17.0 |          27.0 |    17.0 |    10.0 | Sell        |
      | 103.0 |     8.0 |       6.0 |        25.0 |          11.0 |    11.0 |    14.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        25.0 |           5.0 |     5.0 |    20.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    17.0 |    10.0 | Sell |

    When the open order book receives an auction timer event
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id11 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 2.0 |   NaN | Trade    | Filled          | 2.0     | 104.0  | 0.0       | 2.0    | 104.0 |                     |
      | id13 |     3 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 3.0 |   NaN | Trade    | Filled          | 3.0     | 104.0  | 0.0       | 3.0    | 104.0 |                     |
      | id12 |     2 | 00001-2 | 912828Q45 | Market  | AtOpen | Buy  | 7.0 |   NaN | Trade    | Filled          | 7.0     | 104.0  | 0.0       | 7.0    | 104.0 |                     |
      | id21 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 5.0 | 104.0 | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id31 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 8.0 | 103.0 | Canceled | Canceled        | 0.0     | NaN    | 8.0       | 0.0    | NaN   | No match in auction |
      | id41 |    10 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell | 5.0 |   NaN | Trade    | Filled          | 5.0     | 104.0  | 0.0       | 5.0    | 104.0 |                     |
      | id32 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 6.0 | 103.0 | Trade    | Filled          | 6.0     | 104.0  | 0.0       | 6.0    | 104.0 |                     |
      | id22 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 1.0 | 104.0 | Trade    | Filled          | 1.0     | 104.0  | 0.0       | 1.0    | 104.0 |                     |
      | id24 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 8.0 | 104.0 | Trade    | PartiallyFilled | 5.0     | 104.0  | 3.0       | 5.0    | 104.0 |                     |
      | id24 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 8.0 | 104.0 | Canceled | Canceled        | 0.0     | NaN    | 3.0       | 5.0    | 104.0 | No match in auction |
      | id23 |     6 | 00001-2 | 912828Q45 | Limit   | AtOpen | Sell | 7.0 | 104.0 | Canceled | Canceled        | 0.0     | NaN    | 7.0       | 0.0    | NaN   | No match in auction |


  Scenario: Auction - limit order amend price scenario

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif    | side | qty  | price |
      | id11 | 912828Q45 |     1 | 00001-0 | Market  | AtOpen | Buy  | 12.0 |   0.0 |
      | id21 | 912828Q45 |     2 | 00001-0 | Limit   | AtOpen | Buy  |  5.0 | 104.0 |
      | id22 | 912828Q45 |     3 | 00001-0 | Limit   | AtOpen | Sell |  8.0 | 104.0 |
      | id31 | 912828Q45 |     4 | 00001-0 | Limit   | AtOpen | Buy  |  1.0 | 103.0 |
      | id32 | 912828Q45 |     5 | 00001-0 | Limit   | AtOpen | Buy  |  9.0 | 103.0 |
      | id33 | 912828Q45 |     6 | 00001-0 | Limit   | AtOpen | Sell | 12.0 | 103.0 |
      | id41 | 912828Q45 |     7 | 00001-0 | Market  | AtOpen | Sell |  5.0 |   0.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id11 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 12.0 |   0.0 | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id21 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  5.0 | 104.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id22 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  8.0 | 104.0 | New      | New       | 0.0     | NaN    |  8.0      | 0.0    | NaN   |      |
      | id31 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  1.0 | 103.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id32 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  9.0 | 103.0 | New      | New       | 0.0     | NaN    |  9.0      | 0.0    | NaN   |      |
      | id33 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 12.0 | 103.0 | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id41 |     7 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |  5.0 |   0.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |    12.0 |       0.0 |        12.0 |          25.0 |    12.0 |    13.0 | Sell        |
      | 104.0 |     5.0 |       8.0 |        17.0 |          25.0 |    17.0 |     8.0 | Sell        |
      | 103.0 |    10.0 |      12.0 |        27.0 |          17.0 |    17.0 |    10.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        27.0 |           5.0 |     5.0 |    22.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    17.0 |     8.0 | Sell |

    When a replacement request is received
  # New level
      | ordId | clOrdId | qty | price |
      |     4 | 00001-2 | 2.0 | 105.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id31 |     4 | 00001-2 | 912828Q45 | Limit   | AtOpen | Buy  | 2.0 | 105.0 | Replaced | Replaced  |     0.0 |    NaN |       2.0 |    0.0 |   NaN |      |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price 105.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id31 |     4 | 00001-2 | 912828Q45 | Limit   | AtOpen | Buy  | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price 103.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id32 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 9.0 | 0.0     | NaN    | 9.0       | 0.0    | NaN   |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |    12.0 |       0.0 |        12.0 |          25.0 |    12.0 |    13.0 | Sell        |
      | 105.0 |     2.0 |       0.0 |        14.0 |          25.0 |    14.0 |    11.0 | Sell        |
      | 104.0 |     5.0 |       8.0 |        19.0 |          25.0 |    19.0 |     6.0 | Sell        |
      | 103.0 |     9.0 |      12.0 |        28.0 |          17.0 |    17.0 |    11.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        28.0 |           5.0 |     5.0 |    23.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    19.0 |     6.0 | Sell |

    When a replacement request is received
  # New level
      | ordId | clOrdId | qty | price |
      |     4 | 00001-3 | 1.0 | 103.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id31 |     4 | 00001-3 | 912828Q45 | Limit   | AtOpen | Buy  | 1.0 | 103.0 | Replaced | Replaced  | 0.0     | NaN    |       1.0 | 0.0    | NaN   |      |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price 103.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id32 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 9.0 | 0.0     | NaN    | 9.0       | 0.0    | NaN   |
      | id31 |     4 | 00001-3 | 912828Q45 | Limit   | AtOpen | Buy  | 1.0 | 0.0     | NaN    | 1.0       | 0.0    | NaN   |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |    12.0 |       0.0 |        12.0 |          25.0 |    12.0 |    13.0 | Sell        |
      | 105.0 |     0.0 |       0.0 |        12.0 |          25.0 |     0.0 |     0.0 | None        |
      | 104.0 |     5.0 |       8.0 |        17.0 |          25.0 |    17.0 |     8.0 | Sell        |
      | 103.0 |    10.0 |      12.0 |        27.0 |          17.0 |    17.0 |    10.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        27.0 |           5.0 |     5.0 |    22.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 104.0 |    17.0 |     8.0 | Sell |

    When the open order book receives an auction timer event
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side |  qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id11 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 12.0 |   0.0 | Trade    | Filled          |    12.0 | 104.0  |       0.0 |   12.0 | 104.0 |                     |
      | id21 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  5.0 | 104.0 | Trade    | Filled          |     5.0 | 104.0  |       0.0 |    5.0 | 104.0 |                     |
      | id32 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  9.0 | 103.0 | Canceled | Canceled        |     0.0 |   NaN  |       9.0 |    0.0 |   NaN | No match in auction |
      | id31 |     4 | 00001-3 | 912828Q45 | Limit   | AtOpen | Buy  |  1.0 | 103.0 | Canceled | Canceled        |     0.0 |   NaN  |       1.0 |    0.0 |   NaN | No match in auction |
      | id41 |     7 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |  5.0 |   0.0 | Trade    | Filled          |     5.0 | 104.0  |       0.0 |    5.0 | 104.0 |                     |
      | id33 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 12.0 | 103.0 | Trade    | Filled          |    12.0 | 104.0  |       0.0 |   12.0 | 104.0 |                     |
      | id22 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  8.0 | 104.0 | Canceled | Canceled        |     0.0 |   NaN  |       8.0 |    0.0 |   NaN | No match in auction |


  Scenario: Auction - amend order type from market to limit and vice versa

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif    | side | qty  | price |
      | id21 | 912828Q45 |     1 | 00001-0 | Limit   | AtOpen | Buy  |  5.0 | 104.0 |
      | id22 | 912828Q45 |     2 | 00001-0 | Limit   | AtOpen | Sell |  8.0 | 104.0 |
      | id31 | 912828Q45 |     3 | 00001-0 | Limit   | AtOpen | Buy  |  1.0 | 103.0 |
      | id32 | 912828Q45 |     4 | 00001-0 | Limit   | AtOpen | Buy  |  9.0 | 103.0 |
      | id33 | 912828Q45 |     5 | 00001-0 | Limit   | AtOpen | Sell | 12.0 | 103.0 |
      | id41 | 912828Q45 |     6 | 00001-0 | Market  | AtOpen | Sell |  5.0 |   0.0 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side |  qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id21 |     1 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  5.0 | 104.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id22 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  8.0 | 104.0 | New      | New       | 0.0     | NaN    |  8.0      | 0.0    | NaN   |      |
      | id31 |     3 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  1.0 | 103.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id32 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  9.0 | 103.0 | New      | New       | 0.0     | NaN    |  9.0      | 0.0    | NaN   |      |
      | id33 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 12.0 | 103.0 | New      | New       | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      |
      | id41 |     6 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |  5.0 |   0.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | 104.0 |     5.0 |       8.0 |         5.0 |          25.0 |     5.0 |    20.0 | Sell        |
      | 103.0 |    10.0 |      12.0 |        15.0 |          17.0 |    15.0 |     2.0 | Sell        |
      | -Inf  |     0.0 |       5.0 |        15.0 |           5.0 |     5.0 |    10.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 103.0 |    15.0 |     2.0 | Sell |

    When a replacement request is received
  # New level
      | ordId | clOrdId | qty | price | ordType |
      |     3 | 00001-2 | 2.0 |   0.0 | Market  |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id31 |     3 | 00001-2 | 912828Q45 | Market  | AtOpen | Buy  | 2.0 |   0.0 | Replaced | Replaced  |     0.0 |    NaN |       2.0 |    0.0 |   NaN |      |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price Inf are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id31 |     3 | 00001-2 | 912828Q45 | Market  | AtOpen | Buy  | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price 103.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id32 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 9.0 | 0.0     | NaN    | 9.0       | 0.0    | NaN   |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |     2.0 |       0.0 |         2.0 |          25.0 |     2.0 |    23.0 | Sell        |
      | 104.0 |     5.0 |       8.0 |         7.0 |          25.0 |     7.0 |    18.0 | Sell        |
      | 103.0 |     9.0 |      12.0 |        16.0 |          17.0 |    16.0 |     1.0 | Sell        |
      | -Inf  |     0.0 |       5.0 |        16.0 |           5.0 |     5.0 |    11.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 103.0 |    16.0 |     1.0 | Sell |

    When a replacement request is received
  # Old level
      | ordId | clOrdId | qty | price | ordType |
      |     3 | 00001-3 | 1.0 | 103.0 | Limit   |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id31 |     3 | 00001-3 | 912828Q45 | Limit   | AtOpen | Buy  | 1.0 | 103.0 | Replaced | Replaced  | 0.0     | NaN    |       1.0 | 0.0    | NaN   |      |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price 103.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id32 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 9.0 | 0.0     | NaN    | 9.0       | 0.0    | NaN   |
      | id31 |     3 | 00001-3 | 912828Q45 | Limit   | AtOpen | Buy  | 1.0 | 0.0     | NaN    | 1.0       | 0.0    | NaN   |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |     0.0 |       0.0 |         0.0 |          25.0 |     0.0 |     0.0 | None        |
      | 104.0 |     5.0 |       8.0 |         5.0 |          25.0 |     5.0 |    20.0 | Sell        |
      | 103.0 |    10.0 |      12.0 |        15.0 |          17.0 |    15.0 |     2.0 | Sell        |
      | -Inf  |     0.0 |       5.0 |        15.0 |           5.0 |     5.0 |    10.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 103.0 |    15.0 |     2.0 | Sell |

    When the open order book receives an auction timer event
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side |  qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id21 |     1 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  5.0 | 104.0 | Trade    | Filled          |     5.0 | 103.0  |       0.0 |    5.0 | 103.0 |                     |
      | id32 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  9.0 | 103.0 | Trade    | Filled          |     9.0 | 103.0  |       0.0 |    9.0 | 103.0 |                     |
      | id31 |     3 | 00001-3 | 912828Q45 | Limit   | AtOpen | Buy  |  1.0 | 103.0 | Trade    | Filled          |     1.0 | 103.0  |       0.0 |    1.0 | 103.0 |                     |
      | id41 |     6 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |  5.0 |   0.0 | Trade    | Filled          |     5.0 | 103.0  |       0.0 |    5.0 | 103.0 |                     |
      | id33 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 12.0 | 103.0 | Trade    | PartiallyFilled |    10.0 | 103.0  |       2.0 |   10.0 | 103.0 |                     |
      | id33 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 12.0 | 103.0 | Canceled | Canceled        |     0.0 |   NaN  |       2.0 |   10.0 | 103.0 | No match in auction |
      | id22 |     2 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  8.0 | 104.0 | Canceled | Canceled        |     0.0 |   NaN  |       8.0 |    0.0 |   NaN | No match in auction |


  Scenario Outline: Auction corner case: amends / cancels received in only_new phase

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | <tif> | Buy  | 10.0 | 102.0 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | <tif> | Buy  | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
    And the accumulated orders for 912828Q45 and the <bookType> order book filtered by side Buy and price 102.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | <tif> | Buy  | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |

    When the <bookType> order book receives an only_new timer event
    Then the <bookType> accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | 102.0 |    10.0 |       0.0 |         0.0 |           0.0 |     0.0 |     0.0 | None        |

    When a replacement request is received
      | ordId | clOrdId | qty | price | ordType |
      |     1 | 00001-1 | 5.0 |   NaN | Market  |
    Then all rejections sent back to clients are
      | uid | ordId | clOrdId | ordStatus | text                                |
      | id1 |     1 | 00001-1 | Rejected  | Amend not allowed in Only New phase |
    And the accumulated orders for 912828Q45 and the <bookType> order book filtered by side Buy and price 102.0 are
	# the order book has not changed
      | uid | ordId | clOrdId | secId     | ordType | tif   | side | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | <tif> | Buy  | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |

    When a cancel request is received
      | ordId | clOrdId |
      |     1 | 00001-2 |
    Then all rejections sent back to clients are
      | uid | ordId | clOrdId | ordStatus | text                                 |
      | id1 |     1 | 00001-2 | Rejected  | Cancel not allowed in Only New phase |
    And the accumulated orders for 912828Q45 and the <bookType> order book filtered by side Buy and price 102.0 are
	# the order book has not changed
      | uid | ordId | clOrdId | secId     | ordType | tif   | side | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | <tif> | Buy  | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |

    Examples: Relevant Combinations
      | bookType | tif     |
      | open     | AtOpen  |
      | close    | AtClose |

  Scenario: Auction - cancel scenario: market and limit orders are canceled

    When a new order is received
      |  uid | secId     | ordId | clOrdId | ordType | tif    | side | qty  | price |
      | id11 | 912828Q45 |     1 | 00001-0 | Market  | AtOpen | Buy  |  2.0 |   NaN |
      | id12 | 912828Q45 |     2 | 00001-0 | Market  | AtOpen | Buy  | 10.0 |   NaN |
      | id13 | 912828Q45 |     3 | 00001-0 | Market  | AtOpen | Buy  |  3.0 |   NaN |
      | id21 | 912828Q45 |     4 | 00001-0 | Limit   | AtOpen | Buy  |  5.0 | 104.0 |
      | id22 | 912828Q45 |     5 | 00001-0 | Limit   | AtOpen | Sell |  1.0 | 104.0 |
      | id23 | 912828Q45 |     6 | 00001-0 | Limit   | AtOpen | Sell |  6.0 | 104.0 |
      | id24 | 912828Q45 |     7 | 00001-0 | Limit   | AtOpen | Sell |  8.0 | 104.0 |
      | id31 | 912828Q45 |     8 | 00001-0 | Limit   | AtOpen | Buy  |  8.0 | 103.0 |
      | id32 | 912828Q45 |     9 | 00001-0 | Limit   | AtOpen | Sell |  6.0 | 103.0 |
      | id41 | 912828Q45 |    10 | 00001-0 | Market  | AtOpen | Sell |  5.0 |   NaN |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id11 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  |  2.0 |   NaN | New      | New       | 0.0     | NaN    |  2.0      | 0.0    | NaN   |      |
      | id12 |     2 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 10.0 |   NaN | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id13 |     3 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  |  3.0 |   NaN | New      | New       | 0.0     | NaN    |  3.0      | 0.0    | NaN   |      |
      | id21 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  5.0 | 104.0 | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |
      | id22 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  1.0 | 104.0 | New      | New       | 0.0     | NaN    |  1.0      | 0.0    | NaN   |      |
      | id23 |     6 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  6.0 | 104.0 | New      | New       | 0.0     | NaN    |  6.0      | 0.0    | NaN   |      |
      | id24 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  8.0 | 104.0 | New      | New       | 0.0     | NaN    |  8.0      | 0.0    | NaN   |      |
      | id31 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  |  8.0 | 103.0 | New      | New       | 0.0     | NaN    |  8.0      | 0.0    | NaN   |      |
      | id32 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell |  6.0 | 103.0 | New      | New       | 0.0     | NaN    |  6.0      | 0.0    | NaN   |      |
      | id41 |    10 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell |  5.0 |   NaN | New      | New       | 0.0     | NaN    |  5.0      | 0.0    | NaN   |      |

    When a cancel request is received
      | ordId | clOrdId |
      |     2 | 00001-1 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id12 |     2 | 00001-1 | 912828Q45 | Market  | AtOpen | Buy  | 10.0 |   NaN | Canceled | Canceled  | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Buy and price Inf are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id11 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
      | id13 |     3 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |

    When a cancel request is received
      | ordId | clOrdId |
      |     6 | 00001-1 |
    Then all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id23 |     6 | 00001-1 | 912828Q45 | Limit   | AtOpen | Sell |  6.0 | 104.0 | Canceled | Canceled  | 0.0     | NaN    |  6.0      | 0.0    | NaN   |      |
    And the accumulated orders for 912828Q45 and the open order book filtered by side Sell and price 104.0 are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id22 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 1.0 | 0.0     | NaN    |  1.0      | 0.0    | NaN   |
      | id24 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 8.0 | 0.0     | NaN    |  8.0      | 0.0    | NaN   |

    When the open order book receives an imbalance timer event
    Then the open accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | Inf   |     5.0 |       0.0 |         5.0 |          20.0 |     5.0 |    15.0 | Sell        |
      | 104.0 |     5.0 |       9.0 |        10.0 |          20.0 |    10.0 |    10.0 | Sell        |
      | 103.0 |     8.0 |       6.0 |        18.0 |          11.0 |    11.0 |     7.0 | Buy         |
      | -Inf  |     0.0 |       5.0 |        18.0 |           5.0 |     5.0 |    13.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 103.0 |    11.0 |     7.0 | Buy  |

    When the open order book receives an auction timer event
    And all execution reports sent back to clients are
      | uid  | ordId | clOrdId | secId     | ordType | tif    | side | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                |
      | id11 |     1 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 2.0 |   NaN | Trade    | Filled          | 2.0     | 103.0  | 0.0       | 2.0    | 103.0 |                     |
      | id13 |     3 | 00001-0 | 912828Q45 | Market  | AtOpen | Buy  | 3.0 |   NaN | Trade    | Filled          | 3.0     | 103.0  | 0.0       | 3.0    | 103.0 |                     |
      | id21 |     4 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 5.0 | 104.0 | Trade    | Filled          | 5.0     | 103.0  | 0.0       | 5.0    | 103.0 |                     |
      | id31 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 8.0 | 103.0 | Trade    | PartiallyFilled | 1.0     | 103.0  | 7.0       | 1.0    | 103.0 |                     |
      | id31 |     8 | 00001-0 | 912828Q45 | Limit   | AtOpen | Buy  | 8.0 | 103.0 | Canceled | Canceled        | 0.0     | NaN    | 7.0       | 1.0    | 103.0 | No match in auction |
      | id41 |    10 | 00001-0 | 912828Q45 | Market  | AtOpen | Sell | 5.0 |   NaN | Trade    | Filled          | 5.0     | 103.0  | 0.0       | 5.0    | 103.0 |                     |
      | id32 |     9 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 6.0 | 103.0 | Trade    | Filled          | 6.0     | 103.0  | 0.0       | 6.0    | 103.0 |                     |
      | id22 |     5 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 1.0 | 104.0 | Canceled | Canceled        | 0.0     | NaN    | 1.0       | 0.0    | NaN   | No match in auction |
      | id24 |     7 | 00001-0 | 912828Q45 | Limit   | AtOpen | Sell | 8.0 | 104.0 | Canceled | Canceled        | 0.0     | NaN    | 8.0       | 0.0    | NaN   | No match in auction |

