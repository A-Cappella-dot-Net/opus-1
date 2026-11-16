Feature: Cembalo - Pegged orders
  A pegged order (ordType Pegged) follows a reference price given by the orders of the continuous book
  that are not pegged themselves: the best price on its own side (Primary, the default), the best price
  on the opposite side (Market) or the midpoint between the two (MidPrice).
  pegOffsetValue (default 0) is added to the reference price; it is expressed in Ticks (the default),
  in Price units or in BasisPoints of the reference price. A pegged price that does not fall on a price
  increment is rounded, MorePassive (the default) or MoreAggressive.
  The optional price of a pegged order is a cap: the order never goes beyond it. When the price to peg
  at is beyond the cap the order is held at its cap, in the order book, until that price is back within it.
  Primary and Market pegged orders are displayed, MidPrice pegged orders are hidden.
  A pegged order with no reference price is parked: active, but out of the order book.
  The owner of a pegged order is not told when the order is repriced. A Restated execution report with
  restatementReason 3 (Repricing of order) tells the owner when the order stops or resumes following its
  reference price: when it starts or stops being held at its cap, and when it is parked or unparked.

  In the tables below 'price' is the price the client specified (the cap, NaN if none) in orders and
  execution reports, and the price the order rests at in the order book. The one exception is the Restated
  execution report of an order that follows its reference price again, where 'price' is the pegged price.
  'peggedPx' is the PeggedPrice of the execution reports: the price the order rests at in the order book;
  an order that is parked has none.

  Background:
    Given the set of available instruments is
      | secId     | minQty | minQtyIncrement | minPriceIncrement | ordering | maxLevels |
      | 912828Q45 | 1.0    | 1.0             | 0.5               | 1        | 20        |
      | 912828Y21 | 1.0    | 1.0             | 0.01              | 1        | 20        |
      | 912828Z38 | 1.0    | 1.0             | 0.01              | 2        | 20        |
    And all books are initialized in open matching state
    And exchange starts with no active orders


  # ------------------------------------------------------------------------------------------------
  # Primary peg
  # ------------------------------------------------------------------------------------------------

  Scenario: Primary peg with default instructions follows the best bid
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |

  # the pegged order joins the best bid, behind the order that is already there, and it is displayed
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | 100.0    |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | 9.0   | 100.0 | 103.0 | 5.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 100.0 and leaves 9.0 and shown 9.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |

  # a better bid arrives: the pegged order follows it
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id4 | 912828Q45 |     4 | 00004-0 | Limit   | DAY | Buy  | 2.0      | 2.0 | 100.5 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 2.0 | 100.5 | New      | New       | 0.0     | NaN    | 2.0       | 0.0    | NaN   |      |          |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 5.0   | 100.0 | 6.0   | 100.5 | 103.0 | 5.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 100.5 and leaves 6.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |

  # an order joins the price level the pegged order left
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id5 | 912828Q45 |     5 | 00005-0 | Limit   | DAY | Buy  | 1.0      | 1.0 | 100.0 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id5 |     5 | 00005-0 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 100.0 | New      | New       | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      |          |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 6.0   | 100.0 | 6.0   | 100.5 | 103.0 | 5.0   |

  # the best bid is canceled: the pegged order goes back to the previous price level, at the end of its queue
    When a cancel request is received
      | ordId | clOrdId |
      |     4 | 00004-1 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id4 |     4 | 00004-1 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 2.0 | 100.5 | Canceled | Canceled  | 0.0     | NaN    | 2.0       | 0.0    | NaN   |      |          |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | 10.0  | 100.0 | 103.0 | 5.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 100.0 and leaves 10.0 and shown 10.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id5 |     5 | 00005-0 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 0.0     | NaN    | 1.0       | 0.0    | NaN   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |


  Scenario: Primary peg on the sell side follows the best offer and is an iceberg like any other order
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Sell | 1.0      | 4.0 |       | Primary      |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 5.0   | 100.0 | 103.0 | 6.0   | NaN   | 0.0   |
    And order 3 is pegged at 103.0

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id4 | 912828Q45 |     4 | 00004-0 | Limit   | DAY | Sell | 2.0      | 2.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 5.0   | 100.0 | 102.0 | 3.0   | 103.0 | 5.0   |
    And the continuous orders for 912828Q45 and side Sell at level 0 with price 102.0 and leaves 6.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 2.0      | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Sell | 1.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |


  Scenario Outline: Pegged price - <side> <pegPriceType> peg, offset <offset> <offsetType>, <round>, cap <cap>
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price | pegPriceType   | pegOffsetValue | pegOffsetType | pegRoundDirection |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | <side> | 4.0      | 4.0 | <cap> | <pegPriceType> | <offset>       | <offsetType>  | <round>           |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | <side> | 4.0      | 4.0 | <cap> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | <peggedAt> |
    And order 3 is pegged at <peggedAt>

    Examples: Primary peg, the reference is the best price on the same side
      | side | pegPriceType | offset | offsetType  | round          | cap   | peggedAt |
      | Buy  |              |        |             |                |       | 100.0    |
      | Buy  | Primary      | 0      | Ticks       | MorePassive    |       | 100.0    |
      | Buy  | Primary      | 1      | Ticks       |                |       | 100.5    |
      | Buy  | Primary      | -2     |             |                |       | 99.0     |
      | Buy  | Primary      | 0.5    | Price       |                |       | 100.5    |
      | Buy  | Primary      | -0.3   | Price       |                |       | 99.5     |
      | Buy  | Primary      | -0.3   | Price       | MorePassive    |       | 99.5     |
      | Buy  | Primary      | -0.3   | Price       | MoreAggressive |       | 100.0    |
      | Buy  | Primary      | 50     | BasisPoints |                |       | 100.5    |
      | Buy  | Primary      | -10    | BasisPoints |                |       | 99.5     |
      | Buy  | Primary      | -10    | BasisPoints | MoreAggressive |       | 100.0    |
      | Sell |              |        |             |                |       | 103.0    |
      | Sell | Primary      | -1     | Ticks       |                |       | 102.5    |
      | Sell | Primary      | 0.3    | Price       |                |       | 103.5    |
      | Sell | Primary      | 0.3    | Price       | MoreAggressive |       | 103.0    |
      | Sell | Primary      | -100   | BasisPoints |                |       | 102.0    |
      | Sell | Primary      | -100   | BasisPoints | MoreAggressive |       | 101.5    |

    Examples: Market peg, the reference is the best price on the opposite side
      | side | pegPriceType | offset | offsetType  | round          | cap   | peggedAt |
      | Buy  | Market       | -1     | Ticks       |                |       | 102.5    |
      | Buy  | Market       | -0.7   | Price       |                |       | 102.0    |
      | Buy  | Market       | -0.7   | Price       | MoreAggressive |       | 102.5    |
      | Sell | Market       | 1      | Ticks       |                |       | 100.5    |
      | Sell | Market       | 2      |             |                |       | 101.0    |

    Examples: Mid Price peg, the reference is the midpoint between the best bid and the best offer
      | side | pegPriceType | offset | offsetType  | round          | cap   | peggedAt |
      | Buy  | MidPrice     |        |             |                |       | 101.5    |
      | Sell | MidPrice     |        |             |                |       | 101.5    |
      | Buy  | MidPrice     | -0.2   | Price       |                |       | 101.0    |
      | Buy  | MidPrice     | -0.2   | Price       | MoreAggressive |       | 101.5    |
      | Sell | MidPrice     | 0.2    | Price       |                |       | 102.0    |
      | Sell | MidPrice     | 0.2    | Price       | MoreAggressive |       | 101.5    |

    Examples: The price is a cap, and the price to peg at is within it, or right at it
      | side | pegPriceType | offset | offsetType  | round          | cap   | peggedAt |
      | Buy  | Primary      |        |             |                | 101.0 | 100.0    |
      | Buy  | Primary      |        |             |                | 100.0 | 100.0    |
      | Buy  | Primary      | 1      | Ticks       |                | 100.5 | 100.5    |
      | Sell | Primary      |        |             |                | 102.0 | 103.0    |
      | Sell | Primary      |        |             |                | 103.0 | 103.0    |
      | Buy  | MidPrice     |        |             |                | 101.5 | 101.5    |


  Scenario Outline: Pegged price beyond the cap - <side> <pegPriceType> peg, offset <offset>, cap <cap>
  # the pegged price never goes beyond the cap: the order is held at its cap, and its owner is told so
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price | pegPriceType   | pegOffsetValue |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | <side> | 4.0      | 4.0 | <cap> | <pegPriceType> | <offset>       |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | <side> | 4.0      | 4.0 | <cap> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | <cap>    |                   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | <side> | 4.0      | 4.0 | <cap> | Restated | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | <cap>    | 3                 |
    And order 3 is pegged at <cap>

    Examples:
      | side | pegPriceType | offset | cap   |
      | Buy  | Primary      |        | 99.0  |
      | Buy  | Primary      | 3      | 100.5 |
      | Sell | Primary      |        | 104.0 |
      | Sell | Primary      | -3     | 102.5 |
      | Buy  | Market       |        | 102.0 |
      | Sell | Market       |        | 100.5 |
      | Buy  | MidPrice     |        | 101.0 |
      | Sell | MidPrice     |        | 102.0 |


  # ------------------------------------------------------------------------------------------------
  # The cap
  # ------------------------------------------------------------------------------------------------

  Scenario: The pegged order follows the best bid up to its cap and no further
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 100.5 |
    Then order 3 is pegged at 100.0

  # the best bid moves to the cap: the pegged order follows it, it is not held back yet
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id4 | 912828Q45 |     4 | 00004-0 | Limit   | DAY | Buy  | 1.0      | 1.0 | 100.5 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2 | bid2  | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | 5.0   | 100.0 | 5.0   | 100.5 | 103.0 | 5.0   |
    And order 3 is pegged at 100.5

  # the best bid moves beyond the cap, twice: the pegged order stays at its cap, and keeps its place in the queue;
  # its owner gets one Restated execution report, when the order starts being held at its cap (see order 3 below)
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id5 | 912828Q45 |     5 | 00005-0 | Limit   | DAY | Buy  | 1.0      | 1.0 | 101.0 |
      | id6 | 912828Q45 |     6 | 00006-0 | Limit   | DAY | Buy  | 1.0      | 1.0 | 102.5 |
      | id7 | 912828Q45 |     7 | 00007-0 | Limit   | DAY | Buy  | 1.0      | 1.0 | 100.5 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ3 | bid3  | bidQ2 | bid2  | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 5.0   | 100.0 | 6.0   | 100.5 | 1.0   | 101.0 | 1.0   | 102.5 | 103.0 | 5.0   |
    And the continuous orders for 912828Q45 and side Buy at level 2 with price 100.5 and leaves 6.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 0.0     | NaN    | 1.0       | 0.0    | NaN   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id7 |     7 | 00007-0 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 0.0     | NaN    | 1.0       | 0.0    | NaN   |

  # the best bid comes back to the cap, and then below it: the pegged order follows it again;
  # its owner gets one more Restated execution report, when the best bid is back within the cap, and none after that
    When a cancel request is received
      | ordId | clOrdId |
      |     6 | 00006-1 |
      |     5 | 00005-1 |
      |     4 | 00004-1 |
      |     7 | 00007-1 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | 9.0   | 100.0 | 103.0 | 5.0   |
    And order 3 is pegged at 100.0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 100.5 | New      | New       | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      |          |                   |
      | id5 |     5 | 00005-0 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 101.0 | New      | New       | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      |          |                   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0  | 100.5 | Restated | New             | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | 100.5    | 3                 |
      | id6 |     6 | 00006-0 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 102.5 | New      | New       | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      |          |                   |
      | id7 |     7 | 00007-0 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 100.5 | New      | New       | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      |          |                   |
      | id6 |     6 | 00006-1 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 102.5 | Canceled | Canceled  | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      |          |                   |
      | id5 |     5 | 00005-1 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 101.0 | Canceled | Canceled  | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      |          |                   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0  | 100.5 | Restated | New             | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | 100.5    | 3                 |
      | id4 |     4 | 00004-1 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 100.5 | Canceled | Canceled  | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      |          |                   |
      | id7 |     7 | 00007-1 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 100.5 | Canceled | Canceled  | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      |          |                   |


  Scenario: The cap of a sell order is a floor
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Sell | 4.0      | 4.0 | 102.5 |
    Then order 3 is pegged at 103.0

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id4 | 912828Q45 |     4 | 00004-0 | Limit   | DAY | Sell | 1.0      | 1.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 | ask2  | askQ2 |
      | 5.0   | 100.0 | 102.0 | 1.0   | 102.5 | 4.0   | 103.0 | 5.0   |
    And order 3 is pegged at 102.5
  # the best offer is below the cap of the order: the order is held at its cap
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 1.0      | 1.0 | 102.0 | New      | New       | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      |          |                   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Sell | 4.0      | 4.0 | 102.5 | Restated | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | 102.5    | 3                 |

  # the best offer is back above the cap: the order follows it again, and the Restated execution report has the pegged price
    When a cancel request is received
      | ordId | clOrdId |
      |     4 | 00004-1 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id4 |     4 | 00004-1 | 912828Q45 | Limit   | DAY | Sell | 1.0      | 1.0 | 102.0 | Canceled | Canceled  | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      |          |                   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Sell | 4.0      | 4.0 | 103.0 | Restated | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | 103.0    | 3                 |
    And order 3 is pegged at 103.0


  # ------------------------------------------------------------------------------------------------
  # Market peg
  # ------------------------------------------------------------------------------------------------

  Scenario: Market peg follows the best offer, is displayed, and can be hit as the best bid it is
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |
      | id3 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 104.0 |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType | pegOffsetValue |
      | id4 | 912828Q45 |     4 | 00004-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       | Market       | -1             |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 5.0   | 100.0 | 4.0   | 102.5 | 103.0 | 5.0   | 104.0 | 5.0   |
    And order 4 is pegged at 102.5

  # the best offer goes away: the pegged order follows the new one
    When a cancel request is received
      | ordId | clOrdId |
      |     2 | 00002-1 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 5.0   | 100.0 | 4.0   | 103.5 | 104.0 | 5.0   | NaN   | 0.0   |
    And order 4 is pegged at 103.5
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | 102.5    |
      | id2 |     2 | 00002-1 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 | Canceled | Canceled  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |          |

  # a seller aiming at the limit bid trades with the pegged order first: it is the best bid
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id5 | 912828Q45 |     5 | 00005-0 | Limit   | DAY | Sell | 2.0      | 2.0 | 100.0 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id5 |     5 | 00005-0 | 912828Q45 | Limit   | DAY | Sell | 2.0      | 2.0 | 100.0 | New      | New             | 0.0     | NaN    | 2.0       | 0.0    | NaN   |      |          |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Trade    | PartiallyFilled | 2.0     | 103.5  | 2.0       | 2.0    | 103.5 |      | 103.5    |
      | id5 |     5 | 00005-0 | 912828Q45 | Limit   | DAY | Sell | 2.0      | 2.0 | 100.0 | Trade    | Filled          | 2.0     | 103.5  | 0.0       | 2.0    | 103.5 |      |          |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 5.0   | 100.0 | 2.0   | 103.5 | 104.0 | 5.0   |


  Scenario: Market peg with no offset is executable - it takes the best offer, level after level, up to its cap
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 101.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 102.0 |
      | id3 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty  | price | pegPriceType |
      | id4 | 912828Q45 |     4 | 00004-0 | Pegged  | DAY | Buy  | 12.0     | 12.0 | 102.0 | Market       |
  # pegged at 101.0 it takes the first offer; that moves the best offer to 102.0, and the order with it;
  # it then takes the second offer, and stops there: the best offer is now 103.0, beyond its cap
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Buy  | 12.0     | 12.0 | 102.0 | New      | New             | 0.0     | NaN    | 12.0      | 0.0    | NaN   |      | 101.0    |                   |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 5.0  | 101.0 | Trade    | Filled          | 5.0     | 101.0  | 0.0       | 5.0    | 101.0 |      |          |                   |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Buy  | 12.0     | 12.0 | 102.0 | Trade    | PartiallyFilled | 5.0     | 101.0  | 7.0       | 5.0    | 101.0 |      | 101.0    |                   |
      | id2 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 5.0  | 102.0 | Trade    | Filled          | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      |          |                   |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Buy  | 12.0     | 12.0 | 102.0 | Trade    | PartiallyFilled | 5.0     | 102.0  | 2.0       | 10.0   | 101.5 |      | 102.0    |                   |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Buy  | 12.0     | 12.0 | 102.0 | Restated | PartiallyFilled | 0.0     | NaN    | 2.0       | 10.0   | 101.5 |      | 102.0    | 3                 |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 2.0   | 102.0 | 103.0 | 5.0   | NaN   | 0.0   |
    And all continuous orders for 912828Q45 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty  | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id3 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 5.0  | 103.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Buy  | 12.0     | 12.0 | 102.0 | 5.0     | 102.0  | 2.0       | 10.0   | 101.5 |


  # ------------------------------------------------------------------------------------------------
  # Mid Price peg
  # ------------------------------------------------------------------------------------------------

  Scenario: Mid Price peg is hidden, and it gives a better price to the orders that reach it
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 101.0 |

  # the order rests at the midpoint, inside the spread, but the Market Data does not show it
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       | MidPrice     |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | 100.5    |
    And no market data snapshot for 912828Q45 is sent
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 100.5 and leaves 4.0 and shown 0.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side Buy at level 1 with price 100.0 and leaves 5.0 and shown 5.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |

  # a seller hitting the displayed bid trades with the hidden order first, at the midpoint
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id4 | 912828Q45 |     4 | 00004-0 | Limit   | DAY | Sell | 6.0      | 6.0 | 100.0 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus       | lastQty | lastPx             | leavesQty | cumQty | avgPx              | text | peggedPx |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 6.0      | 6.0 | 100.0 | New      | New             | 0.0     | NaN                | 6.0       | 0.0    | NaN                |      |          |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Trade    | Filled          | 4.0     | 100.5              | 0.0       | 4.0    | 100.5              |      | 100.5    |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 | Trade    | PartiallyFilled | 2.0     | 100.0              | 3.0       | 2.0    | 100.0              |      |          |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 6.0      | 6.0 | 100.0 | Trade    | Filled          | 6.0     | 100.33333333333333 | 0.0       | 6.0    | 100.33333333333333 |      |          |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | 3.0   | 100.0 | 101.0 | 5.0   |
    And order 3 is not active


  Scenario: Mid Price pegs trade with each other at the midpoint, and nothing shows in the Market Data
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |              |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 101.0 |              |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       | MidPrice     |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType |
      | id4 | 912828Q45 |     4 | 00004-0 | Pegged  | DAY | Sell | 3.0      | 3.0 |       | MidPrice     |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Sell | 3.0      | 3.0 | NaN   | New      | New             | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      | 100.5    |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Trade    | PartiallyFilled | 3.0     | 100.5  | 1.0       | 3.0    | 100.5 |      | 100.5    |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Sell | 3.0      | 3.0 | NaN   | Trade    | Filled          | 3.0     | 100.5  | 0.0       | 3.0    | 100.5 |      | 100.5    |
    And no market data snapshot for 912828Q45 is sent
    And order 3 is pegged at 100.5
    And order 4 is not active

  # an IOC Mid Price peg takes what is available at the midpoint, the remainder is canceled
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType |
      | id5 | 912828Q45 |     5 | 00005-0 | Pegged  | IOC | Sell | 3.0      | 3.0 |       | MidPrice     |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | peggedPx |
      | id5 |     5 | 00005-0 | 912828Q45 | Pegged  | IOC | Sell | 3.0      | 3.0 | NaN   | New      | New             | 0.0     | NaN    | 3.0       | 0.0    | NaN   |                           | 100.5    |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Trade    | Filled          | 1.0     | 100.5  | 0.0       | 4.0    | 100.5 |                           | 100.5    |
      | id5 |     5 | 00005-0 | 912828Q45 | Pegged  | IOC | Sell | 3.0      | 3.0 | NaN   | Trade    | PartiallyFilled | 1.0     | 100.5  | 2.0       | 1.0    | 100.5 |                           | 100.5    |
      | id5 |     5 | 00005-0 | 912828Q45 | Pegged  | IOC | Sell | 3.0      | 3.0 | NaN   | Canceled | Canceled        | 0.0     | NaN    | 2.0       | 1.0    | 100.5 | Could not match IOC order | 100.5    |
    And no market data snapshot for 912828Q45 is sent
    And order 5 is not active

  # an IOC Mid Price peg that finds nothing at the midpoint is canceled
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType |
      | id6 | 912828Q45 |     6 | 00006-0 | Pegged  | IOC | Buy  | 2.0      | 2.0 |       | MidPrice     |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | peggedPx |
      | id6 |     6 | 00006-0 | 912828Q45 | Pegged  | IOC | Buy  | 2.0      | 2.0 | NaN   | New      | New       | 0.0     | NaN    | 2.0       | 0.0    | NaN   |                           | 100.5    |
      | id6 |     6 | 00006-0 | 912828Q45 | Pegged  | IOC | Buy  | 2.0      | 2.0 | NaN   | Canceled | Canceled  | 0.0     | NaN    | 2.0       | 0.0    | NaN   | Could not match IOC order | 100.5    |
    And no market data snapshot for 912828Q45 is sent
    And all continuous orders for 912828Q45 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id2 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 5.0 | 101.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |


  Scenario: Mid Price peg rounded onto the best bid - displayed orders have priority over the hidden one
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 100.5 |

  # the midpoint, 100.25, is not a valid price: the buy order is rounded down (more passive) onto the best bid
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       | MidPrice     |
    Then no market data snapshot for 912828Q45 is sent
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 100.0 and leaves 9.0 and shown 5.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |

  # a displayed order that arrives later is queued ahead of the hidden one
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id4 | 912828Q45 |     4 | 00004-0 | Limit   | DAY | Buy  | 2.0      | 2.0 | 100.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 7.0   | 100.0 | 100.5 | 5.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 100.0 and leaves 11.0 and shown 7.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | 100.0    |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 2.0 | 100.0 | New      | New       | 0.0     | NaN    | 2.0       | 0.0    | NaN   |      |          |

  # the displayed orders are filled first, the hidden one gets what is left;
  # with no bid left there is no midpoint: what remains of the pegged order is parked
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id5 | 912828Q45 |     5 | 00005-0 | Limit   | DAY | Sell | 8.0      | 8.0 | 100.0 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id5 |     5 | 00005-0 | 912828Q45 | Limit   | DAY | Sell | 8.0      | 8.0 | 100.0 | New      | New             | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |          |                   |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 | Trade    | Filled          | 5.0     | 100.0  | 0.0       | 5.0    | 100.0 |      |          |                   |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 2.0 | 100.0 | Trade    | Filled          | 2.0     | 100.0  | 0.0       | 2.0    | 100.0 |      |          |                   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Trade    | PartiallyFilled | 1.0     | 100.0  | 3.0       | 1.0    | 100.0 |      | 100.0    |                   |
      | id5 |     5 | 00005-0 | 912828Q45 | Limit   | DAY | Sell | 8.0      | 8.0 | 100.0 | Trade    | Filled          | 8.0     | 100.0  | 0.0       | 8.0    | 100.0 |      |          |                   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Restated | PartiallyFilled | 0.0     | NaN    | 3.0       | 1.0    | 100.0 |      |          | 3                 |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | 100.5 | 5.0   |
    And order 3 is parked
    And there are no continuous orders for instrument 912828Q45 and side Buy at level 0


  Scenario: Mid Price peg rounded more aggressively onto the best offer trades with it
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 100.5 |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType | pegRoundDirection |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       | MidPrice     | MoreAggressive    |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | New      | New             | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | 100.5    |
      | id2 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 5.0 | 100.5 | Trade    | PartiallyFilled | 4.0     | 100.5  | 1.0       | 4.0    | 100.5 |      |          |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Trade    | Filled          | 4.0     | 100.5  | 0.0       | 4.0    | 100.5 |      | 100.5    |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 5.0   | 100.0 | 100.5 | 1.0   |


  Scenario: A repriced pegged order that becomes executable is matched
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType | pegRoundDirection |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |              |                   |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 101.0 |              |                   |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       | MidPrice     | MoreAggressive    |
    Then order 3 is pegged at 100.5

  # the new best bid moves the midpoint to 100.75, which rounds up to the best offer
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id4 | 912828Q45 |     4 | 00004-0 | Limit   | DAY | Buy  | 1.0      | 1.0 | 100.5 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 100.5 | New      | New             | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      |          |
      | id2 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 5.0 | 101.0 | Trade    | PartiallyFilled | 4.0     | 101.0  | 1.0       | 4.0    | 101.0 |      |          |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Trade    | Filled          | 4.0     | 101.0  | 0.0       | 4.0    | 101.0 |      | 101.0    |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 5.0   | 100.0 | 1.0   | 100.5 | 101.0 | 1.0   |
    And order 3 is not active


  # ------------------------------------------------------------------------------------------------
  # No reference price: parked orders
  # ------------------------------------------------------------------------------------------------

  Scenario: A pegged order with no reference price is parked until the reference price is available
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id1 |     1 | 00001-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |          |                   |
      | id1 |     1 | 00001-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Restated | New             | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |          | 3                 |
    And no market data snapshot for 912828Q45 is sent
    And order 1 is parked
    And the continuous order book for 912828Q45 is empty

  # a bid arrives: the pegged order enters the order book behind it
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 9.0   | 100.0 | NaN   | 0.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 100.0 and leaves 9.0 and shown 9.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id2 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id1 |     1 | 00001-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |

  # the bid goes away: the pegged order is parked again
    When a cancel request is received
      | ordId | clOrdId |
      |     2 | 00002-1 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | NaN   | 0.0   |
    And order 1 is parked
    And the continuous order book for 912828Q45 is empty
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id2 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |          |                   |
      | id1 |     1 | 00001-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 100.0 | Restated | New             | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | 100.0    | 3                 |
      | id2 |     2 | 00002-1 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 | Canceled | Canceled  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |          |                   |
      | id1 |     1 | 00001-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Restated | New             | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |          | 3                 |

  # a parked order can be canceled, and nobody but its owner knows
    When a cancel request is received
      | ordId | clOrdId |
      |     1 | 00001-1 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id1 |     1 | 00001-1 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Canceled | Canceled  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |          |
    And no market data snapshot for 912828Q45 is sent
    And order 1 is not active


  Scenario: An IOC pegged order with no reference price is canceled
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType |
      | id1 | 912828Q45 |     1 | 00001-0 | Pegged  | IOC | Buy  | 4.0      | 4.0 |       | Market       |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | peggedPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Pegged  | IOC | Buy  | 4.0      | 4.0 | NaN   | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |                           |          |
      | id1 |     1 | 00001-0 | 912828Q45 | Pegged  | IOC | Buy  | 4.0      | 4.0 | NaN   | Canceled | Canceled  | 0.0     | NaN    | 4.0       | 0.0    | NaN   | Could not match IOC order |          |
    And no market data snapshot for 912828Q45 is sent
    And order 1 is not active


  Scenario: Pegged orders are not a reference for other pegged orders
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |

  # a Mid Price peg needs both a bid and an offer
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType | pegOffsetValue |
      | id2 | 912828Q45 |     2 | 00002-0 | Pegged  | DAY | Sell | 4.0      | 4.0 |       | MidPrice     |                |
    Then no market data snapshot for 912828Q45 is sent
    And order 2 is parked

  # the Market peg is a displayed offer, the best one, yet the Mid Price peg remains parked
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType | pegOffsetValue |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Sell | 3.0      | 3.0 |       | Market       | 1              |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 |
      | 5.0   | 100.0 | 100.5 | 3.0   | NaN   | 0.0   |
    And order 3 is pegged at 100.5
    And order 2 is parked

  # an offer that is not pegged arrives: the midpoint is now (100.0 + 102.0) / 2
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id4 | 912828Q45 |     4 | 00004-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 | ask1  | askQ1 | ask2  | askQ2 |
      | 5.0   | 100.0 | 100.5 | 3.0   | 102.0 | 5.0   | NaN   | 0.0   |
    And order 2 is pegged at 101.0
    And order 3 is pegged at 100.5
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id2 |     2 | 00002-0 | 912828Q45 | Pegged  | DAY | Sell | 4.0      | 4.0 | NaN   | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |          |                   |
      | id2 |     2 | 00002-0 | 912828Q45 | Pegged  | DAY | Sell | 4.0      | 4.0 | NaN   | Restated | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |          | 3                 |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Sell | 3.0      | 3.0 | NaN   | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      | 100.5    |                   |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 5.0 | 102.0 | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |          |                   |
      | id2 |     2 | 00002-0 | 912828Q45 | Pegged  | DAY | Sell | 4.0      | 4.0 | 101.0 | Restated | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | 101.0    | 3                 |
    And all continuous orders for 912828Q45 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 5.0 | 102.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id2 |     2 | 00002-0 | 912828Q45 | Pegged  | DAY | Sell | 4.0      | 4.0 | 101.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Sell | 3.0      | 3.0 | 100.5 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |


  Scenario: Pegged orders that are repriced together keep their arrival order
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegOffsetValue |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |                |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |                |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       | 1              |
      | id4 | 912828Q45 |     4 | 00004-0 | Pegged  | DAY | Buy  | 3.0      | 3.0 |       |                |
      | id5 | 912828Q45 |     5 | 00005-0 | Pegged  | DAY | Buy  | 2.0      | 2.0 |       |                |
  # order 3 improves the best bid, but orders 4 and 5 peg to the best bid that is not pegged
    Then all continuous orders for 912828Q45 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id2 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 100.5 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Buy  | 3.0      | 3.0 | 100.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id5 |     5 | 00005-0 | 912828Q45 | Pegged  | DAY | Buy  | 2.0      | 2.0 | 100.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id6 | 912828Q45 |     6 | 00006-0 | Limit   | DAY | Buy  | 1.0      | 1.0 | 101.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2 | bid2  | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 5.0   | 100.0 | 6.0   | 101.0 | 4.0   | 101.5 | 103.0 | 5.0   |
    And all continuous orders for 912828Q45 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id2 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 101.5 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id6 |     6 | 00006-0 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 101.0 | 0.0     | NaN    | 1.0       | 0.0    | NaN   |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Buy  | 3.0      | 3.0 | 101.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id5 |     5 | 00005-0 | 912828Q45 | Pegged  | DAY | Buy  | 2.0      | 2.0 | 101.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |

  # with no bid other than the pegged ones, all of them are parked
    When a cancel request is received
      | ordId | clOrdId |
      |     6 | 00006-1 |
      |     1 | 00001-1 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | 103.0 | 5.0   |
    And order 3 is parked
    And order 4 is parked
    And order 5 is parked


  Scenario: The order a pegged order refers to is filled - the pegged order is parked, then follows the next bid
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id4 | 912828Q45 |     4 | 00004-0 | Limit   | DAY | Sell | 7.0      | 7.0 | 100.0 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 7.0      | 7.0 | 100.0 | New      | New             | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |          |                   |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 | Trade    | Filled          | 5.0     | 100.0  | 0.0       | 5.0    | 100.0 |      |          |                   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Trade    | PartiallyFilled | 2.0     | 100.0  | 2.0       | 2.0    | 100.0 |      | 100.0    |                   |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | DAY | Sell | 7.0      | 7.0 | 100.0 | Trade    | Filled          | 7.0     | 100.0  | 0.0       | 7.0    | 100.0 |      |          |                   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Restated | PartiallyFilled | 0.0     | NaN    | 2.0       | 2.0    | 100.0 |      |          | 3                 |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | 103.0 | 5.0   |
    And order 3 is parked

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id5 | 912828Q45 |     5 | 00005-0 | Limit   | DAY | Buy  | 1.0      | 1.0 | 99.0  |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id5 |     5 | 00005-0 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 99.0  | New      | New             | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      |          |                   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 99.0  | Restated | PartiallyFilled | 0.0     | NaN    | 2.0       | 2.0    | 100.0 |      | 99.0     | 3                 |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 3.0   | 99.0  | 103.0 | 5.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 99.0 and leaves 3.0 and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id5 |     5 | 00005-0 | 912828Q45 | Limit   | DAY | Buy  | 1.0      | 1.0 | 0.0     | NaN    | 1.0       | 0.0    | NaN   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 2.0     | 100.0  | 2.0       | 2.0    | 100.0 |


  Scenario: A Market peg that takes all the offers is parked - unparked by the next offer, it takes it and is parked again
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 101.0 |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType |
      | id2 | 912828Q45 |     2 | 00002-0 | Pegged  | DAY | Buy  | 8.0      | 8.0 |       | Market       |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id2 |     2 | 00002-0 | 912828Q45 | Pegged  | DAY | Buy  | 8.0      | 8.0 | NaN   | New      | New             | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      | 101.0    |                   |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 5.0 | 101.0 | Trade    | Filled          | 5.0     | 101.0  | 0.0       | 5.0    | 101.0 |      |          |                   |
      | id2 |     2 | 00002-0 | 912828Q45 | Pegged  | DAY | Buy  | 8.0      | 8.0 | NaN   | Trade    | PartiallyFilled | 5.0     | 101.0  | 3.0       | 5.0    | 101.0 |      | 101.0    |                   |
      | id2 |     2 | 00002-0 | 912828Q45 | Pegged  | DAY | Buy  | 8.0      | 8.0 | NaN   | Restated | PartiallyFilled | 0.0     | NaN    | 3.0       | 5.0    | 101.0 |      |          | 3                 |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | NaN   | 0.0   |
    And order 2 is parked

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id3 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | Sell | 2.0      | 2.0 | 102.0 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx              | text | peggedPx | restatementReason |
      | id3 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Sell | 2.0      | 2.0 | 102.0 | New      | New             | 0.0     | NaN    | 2.0       | 0.0    | NaN                |      |          |                   |
      | id2 |     2 | 00002-0 | 912828Q45 | Pegged  | DAY | Buy  | 8.0      | 8.0 | 102.0 | Restated | PartiallyFilled | 0.0     | NaN    | 3.0       | 5.0    | 101.0              |      | 102.0    | 3                 |
      | id3 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | Sell | 2.0      | 2.0 | 102.0 | Trade    | Filled          | 2.0     | 102.0  | 0.0       | 2.0    | 102.0              |      |          |                   |
      | id2 |     2 | 00002-0 | 912828Q45 | Pegged  | DAY | Buy  | 8.0      | 8.0 | NaN   | Trade    | PartiallyFilled | 2.0     | 102.0  | 1.0       | 7.0    | 101.28571428571429 |      | 102.0    |                   |
      | id2 |     2 | 00002-0 | 912828Q45 | Pegged  | DAY | Buy  | 8.0      | 8.0 | NaN   | Restated | PartiallyFilled | 0.0     | NaN    | 1.0       | 7.0    | 101.28571428571429 |      |          | 3                 |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | NaN   | 0.0   |
    And order 2 is parked


  # ------------------------------------------------------------------------------------------------
  # Amend, cancel, logout
  # ------------------------------------------------------------------------------------------------

  Scenario: Amending a pegged order - quantity and cap
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 101.0 |
      | id4 | 912828Q45 |     4 | 00004-0 | Pegged  | DAY | Buy  | 2.0      | 2.0 |       |

  # a smaller quantity: the order keeps its place in the queue
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty | price | ordType |
      |     3 | 00003-1 |      3.0 | 3.0 | 101.0 | Pegged  |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id3 |     3 | 00003-1 | 912828Q45 | Pegged  | DAY | Buy  | 3.0      | 3.0 | 101.0 | Replaced | Replaced  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      | 100.0    |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | 10.0  | 100.0 | 103.0 | 5.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 100.0 and leaves 10.0 and shown 10.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id3 |     3 | 00003-1 | 912828Q45 | Pegged  | DAY | Buy  | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Buy  | 2.0      | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |

  # a cap below the best bid: the order moves to its new cap
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty | price | ordType |
      |     3 | 00003-2 |      3.0 | 3.0 | 99.5  | Pegged  |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id3 |     3 | 00003-2 | 912828Q45 | Pegged  | DAY | Buy  | 3.0      | 3.0 | 99.5  | Replaced | Replaced  | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      | 99.5     |                   |
      | id3 |     3 | 00003-2 | 912828Q45 | Pegged  | DAY | Buy  | 3.0      | 3.0  | 99.5  | Restated | New             | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      | 99.5     | 3                 |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 3.0   | 99.5  | 7.0   | 100.0 | 103.0 | 5.0   |
    And order 3 is pegged at 99.5

  # no cap anymore, and a larger quantity: the order is back at the best bid, at the end of the queue
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty | price | ordType |
      |     3 | 00003-3 |      6.0 | 6.0 |       | Pegged  |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id3 |     3 | 00003-3 | 912828Q45 | Pegged  | DAY | Buy  | 6.0      | 6.0 | NaN   | Replaced | Replaced  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      | 100.0    |                   |
      | id3 |     3 | 00003-3 | 912828Q45 | Pegged  | DAY | Buy  | 6.0      | 6.0  | 100.0 | Restated | New             | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      | 100.0    | 3                 |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | 13.0  | 100.0 | 103.0 | 5.0   |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 100.0 and leaves 13.0 and shown 13.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Buy  | 2.0      | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
      | id3 |     3 | 00003-3 | 912828Q45 | Pegged  | DAY | Buy  | 6.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |

  # a pegged order cannot become a limit order, nor the other way around
    When a replacement request is received
      | ordId | clOrdId | shownQty | qty | price | ordType |
      |     3 | 00003-4 |      6.0 | 6.0 | 100.0 | Limit   |
      |     1 | 00001-1 |      5.0 | 5.0 | 100.0 | Pegged  |
    Then all rejections sent back to clients are
      | uid | ordId | clOrdId | ordStatus | text                                   |
      | id3 |     3 | 00003-4 | Rejected  | Cannot amend to or from a Pegged order |
      | id1 |     1 | 00001-1 | Rejected  | Cannot amend to or from a Pegged order |
    And no execution reports are sent
    And no market data snapshot for 912828Q45 is sent


  Scenario: Canceling pegged orders, by request and at logout
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |              |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 101.0 |              |
      | id2 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       | Primary      |
      | id2 | 912828Q45 |     4 | 00004-0 | Pegged  | DAY | Sell | 3.0      | 3.0 |       | MidPrice     |
      | id3 | 912828Q45 |     5 | 00005-0 | Pegged  | DAY | Sell | 2.0      | 2.0 |       | MidPrice     |
      | id3 | 912828Q45 |     6 | 00006-0 | Pegged  | DAY | Sell | 1.0      | 1.0 |       | Primary      |

  # canceling a hidden order does not show in the Market Data
    When a cancel request is received
      | ordId | clOrdId |
      |     5 | 00005-1 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id3 |     5 | 00005-1 | 912828Q45 | Pegged  | DAY | Sell | 2.0      | 2.0 | NaN   | Canceled | Canceled  | 0.0     | NaN    | 2.0       | 0.0    | NaN   |      | 100.5    |
    And no market data snapshot for 912828Q45 is sent

  # canceling a displayed one does
    When a cancel request is received
      | ordId | clOrdId |
      |     6 | 00006-1 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id3 |     6 | 00006-1 | 912828Q45 | Pegged  | DAY | Sell | 1.0      | 1.0 | NaN   | Canceled | Canceled  | 0.0     | NaN    | 1.0       | 0.0    | NaN   |      | 101.0    |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 9.0   | 100.0 | 101.0 | 5.0   |

    When user id2 logs out
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text        | peggedPx |
      | id2 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Canceled | Canceled  | 0.0     | NaN    | 4.0       | 0.0    | NaN   | User logout | 100.0    |
      | id2 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Sell | 3.0      | 3.0 | NaN   | Canceled | Canceled  | 0.0     | NaN    | 3.0       | 0.0    | NaN   | User logout | 100.5    |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 5.0   | 100.0 | 101.0 | 5.0   |
    And all continuous orders for 912828Q45 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | Sell | 5.0      | 5.0 | 101.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |


  # ------------------------------------------------------------------------------------------------
  # Orders that are not accepted
  # ------------------------------------------------------------------------------------------------

  Scenario Outline: Pegged order rejected - <text>
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side | shownQty | qty | price   | pegPriceType   | pegOffsetValue | pegOffsetType | pegRoundDirection |
      | id3 | 912828Q45 |     0 | 00003-0 | Pegged  | <tif> | Buy  | 4.0      | 4.0 | <price> | <pegPriceType> | <offset>       | <offsetType>  | <round>           |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side | shownQty | qty | price   | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text   | peggedPx |
      | id3 |     0 | 00003-0 | 912828Q45 | Pegged  | <tif> | Buy  | 4.0      | 4.0 | <price> | Rejected | Rejected  | 0.0     | NaN    | 4.0       | 0.0    | NaN   | <text> |          |
    And no market data snapshot for 912828Q45 is sent
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 100.0 and leaves 5.0 and shown 5.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |

    Examples: Pegged orders target the continuous book
      | tif     | price | pegPriceType | offset | offsetType | round | text                                                   |
      | AtOpen  |       |              |        |            |       | Pegged orders are only accepted in the continuous book |
      | AtClose |       | MidPrice     |        |            |       | Pegged orders are only accepted in the continuous book |

    Examples: Peg instructions that are not supported
      | tif     | price | pegPriceType | offset | offsetType | round | text                                 |
      | DAY     |       | 1            |        |            |       | PegPriceType 1 is not supported      |
      | DAY     |       | 3            |        |            |       | PegPriceType 3 is not supported      |
      | DAY     |       | 9            |        |            |       | PegPriceType 9 is not supported      |
      | DAY     |       |              | 1      | PriceTier  |       | PegOffsetType 3 is not supported     |
      | DAY     |       |              |        |            | 3     | PegRoundDirection 3 is not supported |
      | DAY     |       |              | NaN    |            |       | PegOffsetValue NaN is not valid      |

    Examples: The cap must be a valid price
      | tif     | price | pegPriceType | offset | offsetType | round | text                                                  |
      | DAY     | 100.3 |              |        |            |       | Price 100.3 does not align to minPriceIncrement of 0.5 |


  Scenario: Pegged orders are only accepted while the continuous book is matching
    Given the continuous order book receives a non_matching timer event
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     0 | 00001-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text                                                             | peggedPx |
      | id1 |     0 | 00001-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Rejected | Rejected  | 0.0     | NaN    | 4.0       | 0.0    | NaN   | Pegged orders are only accepted in the continuous matching phase |          |

    Given the continuous order book receives a matching timer event
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-1 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id1 |     1 | 00001-1 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |          |                   |
      | id1 |     1 | 00001-1 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Restated | New             | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |          | 3                 |

    Given the continuous order book receives a close timer event
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     0 | 00001-2 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text                 | peggedPx |
      | id1 |     0 | 00001-2 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Rejected | Rejected  | 0.0     | NaN    | 4.0       | 0.0    | NaN   | Instrument is CLOSED |          |


  Scenario: Only the Local peg scope is supported
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegScope |
      | id3 | 912828Q45 |     0 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       | 2        |
      | id3 | 912828Q45 |     0 | 00003-1 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       | 4        |
      | id3 | 912828Q45 |     3 | 00003-2 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       | Local    |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text                        | peggedPx |
      | id3 |     0 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Rejected | Rejected  | 0.0     | NaN    | 4.0       | 0.0    | NaN   | PegScope 2 is not supported |          |
      | id3 |     0 | 00003-1 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | Rejected | Rejected  | 0.0     | NaN    | 4.0       | 0.0    | NaN   | PegScope 4 is not supported |          |
      | id3 |     3 | 00003-2 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | NaN   | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |                             | 100.0    |
    And order 3 is pegged at 100.0


  # ------------------------------------------------------------------------------------------------
  # Close auction
  # ------------------------------------------------------------------------------------------------

  Scenario: A hidden Mid Price peg counts in the close auction imbalance and in the close price
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif     | side | shownQty | qty | price | pegPriceType |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY     | Buy  | 5.0      | 5.0 | 100.0 |              |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY     | Sell | 5.0      | 5.0 | 102.0 |              |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY     | Buy  | 4.0      | 4.0 |       | MidPrice     |
      | id4 | 912828Q45 |     4 | 00004-0 | Limit   | AtClose | Sell | 0.0      | 6.0 | 101.0 |              |
    Then order 3 is pegged at 101.0

  # the hidden order is the only bid the AtClose offer can match: without it there would be nothing to match
    When the close order book receives an imbalance timer event
    Then the close accumulating order book for 912828Q45 contains
      | price | bidSize | offerSize | bidPressure | offerPressure | matched | surplus | surplusSide |
      | 102.0 |     0.0 |       5.0 |         0.0 |          11.0 |     0.0 |    11.0 | Sell        |
      | 101.0 |     4.0 |       6.0 |         4.0 |           6.0 |     4.0 |     2.0 | Sell        |
      | 100.0 |     5.0 |       0.0 |         9.0 |           0.0 |     0.0 |     9.0 | Buy         |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 101.0 |     4.0 |     2.0 | Sell |
    And no execution reports are sent
    And no market data snapshot for 912828Q45 is sent

  # the auction is run at the pegged price of the hidden order, which is filled
    When the close order book receives an auction timer event
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | peggedPx |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY     | Buy  | 4.0      | 4.0 | NaN   | Trade    | Filled          | 4.0     | 101.0  | 0.0       | 4.0    | 101.0 |                     | 101.0    |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY     | Buy  | 5.0      | 5.0 | 100.0 | Canceled | Canceled        | 0.0     | NaN    | 5.0       | 0.0    | NaN   | No match in auction |          |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | AtClose | Sell | 0.0      | 6.0 | 101.0 | Trade    | PartiallyFilled | 4.0     | 101.0  | 2.0       | 4.0    | 101.0 |                     |          |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | AtClose | Sell | 0.0      | 6.0 | 101.0 | Canceled | Canceled        | 0.0     | NaN    | 2.0       | 4.0    | 101.0 | No match in auction |          |
      | id2 |     2 | 00002-0 | 912828Q45 | Limit   | DAY     | Sell | 5.0      | 5.0 | 102.0 | Canceled | Canceled        | 0.0     | NaN    | 5.0       | 0.0    | NaN   | No match in auction |          |
    And the imbalance market data snapshot for 912828Q45 is
      | price | matched | surplus | side |
      | 101.0 |     4.0 |     2.0 | Sell |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | NaN   | 0.0   |
    And the continuous order book for 912828Q45 is empty
    And the close accumulating order book for 912828Q45 is empty
    And order 3 is not active



  Scenario: Pegged orders take part in the close auction at their pegged price - what is not matched is canceled
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif     | side | shownQty | qty | price | pegPriceType |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY     | Buy  | 5.0      | 5.0 | 100.0 |              |
      | id2 | 912828Q45 |     2 | 00002-0 | Pegged  | DAY     | Buy  | 4.0      | 4.0 |       | Primary      |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY     | Buy  | 3.0      | 3.0 |       | Market       |
      | id4 | 912828Q45 |     4 | 00004-0 | Limit   | AtClose | Sell | 0.0      | 6.0 | 100.0 |              |
      | id5 | 912828Q45 |     5 | 00005-0 | Pegged  | DAY     | Buy  | 2.0      | 2.0 |       | Primary      |
  # there is no offer in the continuous book: the Market peg is parked
    Then order 2 is pegged at 100.0
    And order 3 is parked
    And order 5 is pegged at 100.0

    When the close order book receives an auction timer event
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif     | side | shownQty | qty | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | peggedPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY     | Buy  | 5.0      | 5.0 | 100.0 | Trade    | Filled          | 5.0     | 100.0  | 0.0       | 5.0    | 100.0 |                     |          |
      | id2 |     2 | 00002-0 | 912828Q45 | Pegged  | DAY     | Buy  | 4.0      | 4.0 | NaN   | Trade    | PartiallyFilled | 1.0     | 100.0  | 3.0       | 1.0    | 100.0 |                     | 100.0    |
      | id2 |     2 | 00002-0 | 912828Q45 | Pegged  | DAY     | Buy  | 4.0      | 4.0 | NaN   | Canceled | Canceled        | 0.0     | NaN    | 3.0       | 1.0    | 100.0 | No match in auction | 100.0    |
      | id5 |     5 | 00005-0 | 912828Q45 | Pegged  | DAY     | Buy  | 2.0      | 2.0 | NaN   | Canceled | Canceled        | 0.0     | NaN    | 2.0       | 0.0    | NaN   | No match in auction | 100.0    |
      | id4 |     4 | 00004-0 | 912828Q45 | Limit   | AtClose | Sell | 0.0      | 6.0 | 100.0 | Trade    | Filled          | 6.0     | 100.0  | 0.0       | 6.0    | 100.0 |                     |          |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY     | Buy  | 3.0      | 3.0 | NaN   | Canceled | Canceled        | 0.0     | NaN    | 3.0       | 0.0    | NaN   | No match in auction |          |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | NaN   | 0.0   |
    And the continuous order book for 912828Q45 is empty
    And the close accumulating order book for 912828Q45 is empty
    And order 1 is not active
    And order 2 is not active
    And order 3 is not active
    And order 5 is not active


  # ------------------------------------------------------------------------------------------------
  # Decimal price increments, ordering by yield
  # ------------------------------------------------------------------------------------------------

  Scenario: A pegged price is the very same price a client would send - the orders share the price level
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price  |
      | id1 | 912828Y21 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.03 |
      | id2 | 912828Y21 |     2 | 00002-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.02 |
      | id3 | 912828Y21 |     3 | 00003-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 100.10 |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType | pegOffsetValue |
      | id4 | 912828Y21 |     4 | 00004-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 |       | Primary      | -1             |
    Then a market data snapshot for 912828Y21 is sent to subscribers
      | bidQ2 | bid2  | bidQ1 | bid1   | bidQ0 | bid0   | ask0   | askQ0 |
      | 0.0   | NaN   | 9.0   | 100.02 | 5.0   | 100.03 | 100.10 | 5.0   |
    And the continuous orders for 912828Y21 and side Buy at level 1 with price 100.02 and leaves 9.0 and shown 9.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id2 |     2 | 00002-0 | 912828Y21 | Limit   | DAY | Buy  | 5.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
      | id4 |     4 | 00004-0 | 912828Y21 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |

  # the midpoint, 100.065, is rounded up for a sell order (more passive)
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType | pegOffsetValue |
      | id5 | 912828Y21 |     5 | 00005-0 | Pegged  | DAY | Sell | 2.0      | 2.0 |       | MidPrice     |                |
    Then no market data snapshot for 912828Y21 is sent
    And order 5 is pegged at 100.07

  # a limit order at that very price is the new best offer: the midpoint is now 100.05
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price  |
      | id6 | 912828Y21 |     6 | 00006-0 | Limit   | DAY | Sell | 1.0      | 1.0 | 100.07 |
    Then a market data snapshot for 912828Y21 is sent to subscribers
      | bidQ1 | bid1   | bidQ0 | bid0   | ask0   | askQ0 | ask1   | askQ1 |
      | 9.0   | 100.02 | 5.0   | 100.03 | 100.07 | 1.0   | 100.10 | 5.0   |
    And order 5 is pegged at 100.05
    And order 4 is pegged at 100.02


  Scenario Outline: Ordering by yield - <side> <pegPriceType> peg, offset <offset>, <round>, cap <cap>
  # the lower the yield the higher the price: the best bid is the lowest yield bid, the best offer the highest yield offer
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Z38 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 2.50  |
      | id2 | 912828Z38 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 2.45  |
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price | pegPriceType   | pegOffsetValue | pegRoundDirection |
      | id3 | 912828Z38 |     3 | 00003-0 | Pegged  | DAY | <side> | 4.0      | 4.0 | <cap> | <pegPriceType> | <offset>       | <round>           |
    Then order 3 is pegged at <peggedAt>

    Examples:
      | side | pegPriceType | offset | round          | cap  | peggedAt |
      | Buy  | Primary      |        |                |      | 2.50     |
      | Buy  | Primary      | 1      |                |      | 2.51     |
      | Buy  | Primary      | -2     |                |      | 2.48     |
      | Buy  | Primary      | -2     |                | 2.49 | 2.49     |
      | Buy  | Primary      | -2     |                | 2.47 | 2.48     |
      | Sell | Primary      |        |                |      | 2.45     |
      | Sell | Primary      | 2      |                |      | 2.47     |
      | Sell | Primary      | 2      |                | 2.46 | 2.46     |
      | Buy  | Market       | 1      |                |      | 2.46     |
      | Sell | Market       | -1     |                |      | 2.49     |
      | Buy  | MidPrice     |        |                |      | 2.48     |
      | Buy  | MidPrice     |        | MoreAggressive |      | 2.47     |
      | Sell | MidPrice     |        |                |      | 2.47     |
      | Sell | MidPrice     |        | MoreAggressive |      | 2.48     |


  # ------------------------------------------------------------------------------------------------
  # FIX layer
  # The orders of the scenarios below arrive as FIX messages: they are encoded, decoded and then parsed
  # by the very decoder the ExchangeServer uses. In the tables of the FIX messages the columns are named
  # after the FIX fields, the cells hold the raw FIX values (OrdType P = Pegged, TimeInForce 0 = DAY,
  # Side 1 = Buy), and a field with an empty cell is not part of the message.
  # ------------------------------------------------------------------------------------------------

  Scenario Outline: NewOrderSingle FIX message - Price <Price>, PegPriceType <PegPriceType>, PegRoundDirection <PegRoundDirection>, PegOffsetValue <PegOffsetValue>, PegOffsetType <PegOffsetType>, PegScope <PegScope>
  # a peg instruction that is not in the message takes its default value: Primary peg (5), More Passive (2), offset 0, in Ticks (2), Local (1)
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |
    When a NewOrderSingle FIX message is received
      | Username | ClOrdID | Symbol    | OrdType | TimeInForce | Side | OrderQty | MaxShow | Price   | PegPriceType   | PegRoundDirection   | PegOffsetValue   | PegOffsetType   | PegScope   |
      | id3      | 00003-0 | 912828Q45 | P       | 0           | 1    | 4.0      | 4.0     | <Price> | <PegPriceType> | <PegRoundDirection> | <PegOffsetValue> | <PegOffsetType> | <PegScope> |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price   | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | <Price> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | <peggedAt> |
    And order 3 is pegged at <peggedAt>

    Examples: No peg instruction at all, and each instruction on its own
      | Price | PegPriceType | PegRoundDirection | PegOffsetValue | PegOffsetType | PegScope | peggedAt |
      |       |              |                   |                |               |          | 100.0    |
      |       | 5            |                   |                |               |          | 100.0    |
      |       | 4            |                   | -1             |               |          | 102.5    |
      |       | 2            |                   |                |               |          | 101.5    |
      |       |              | 1                 |                |               |          | 100.0    |
      |       |              |                   | -1             |               |          | 99.5     |
      |       |              |                   |                | 0             |          | 100.0    |
      |       |              |                   |                |               | 1        | 100.0    |
      | 100.5 |              |                   |                |               |          | 100.0    |

    Examples: The offset is in Ticks unless stated otherwise, and the rounding is More Passive unless stated otherwise
      | Price | PegPriceType | PegRoundDirection | PegOffsetValue | PegOffsetType | PegScope | peggedAt |
      |       |              |                   | -1             | 2             |          | 99.5     |
      |       |              |                   | -1             | 0             |          | 99.0     |
      |       |              |                   | -0.3           | 0             |          | 99.5     |
      |       |              | 2                 | -0.3           | 0             |          | 99.5     |
      |       |              | 1                 | -0.3           | 0             |          | 100.0    |
      |       |              |                   | 50             | 1             |          | 100.5    |

    Examples: All of them
      | Price | PegPriceType | PegRoundDirection | PegOffsetValue | PegOffsetType | PegScope | peggedAt |
      | 102.5 | 4            | 1                 | -0.7           | 0             | 1        | 102.5    |
      | 103.0 | 4            | 1                 | -0.7           | 0             | 1        | 102.5    |
      | 103.0 | 4            | 2                 | -0.7           | 0             | 1        | 102.0    |
      | 101.0 | 2            | 2                 | -1             | 2             | 1        | 101.0    |


  Scenario Outline: NewOrderSingle FIX message - Price <Price> is a cap the pegged price would go beyond (PegPriceType <PegPriceType>, PegOffsetValue <PegOffsetValue>)
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |
    When a NewOrderSingle FIX message is received
      | Username | ClOrdID | Symbol    | OrdType | TimeInForce | Side | OrderQty | MaxShow | Price   | PegPriceType   | PegOffsetValue   |
      | id3      | 00003-0 | 912828Q45 | P       | 0           | 1    | 4.0      | 4.0     | <Price> | <PegPriceType> | <PegOffsetValue> |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price   | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | <Price> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | <Price>  |                   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | <Price> | Restated | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | <Price>  | 3                 |
    And order 3 is pegged at <Price>

    Examples:
      | Price | PegPriceType | PegOffsetValue |
      | 99.0  |              |                |
      | 100.0 |              | 2              |
      | 102.5 | 4            |                |
      | 101.0 | 2            |                |


  Scenario Outline: NewOrderSingle FIX message rejected - <text>
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |
    When a NewOrderSingle FIX message is received
      | Username | ClOrdID | Symbol    | OrdType | TimeInForce   | Side | OrderQty | MaxShow | Price   | PegPriceType   | PegRoundDirection   | PegOffsetValue   | PegOffsetType   | PegScope   |
      | id3      | 00003-0 | 912828Q45 | P       | <TimeInForce> | 1    | 4.0      | 4.0     | <Price> | <PegPriceType> | <PegRoundDirection> | <PegOffsetValue> | <PegOffsetType> | <PegScope> |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side | shownQty | qty | price   | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text   |
      | id3 |     0 | 00003-0 | 912828Q45 | Pegged  | <tif> | Buy  | 4.0      | 4.0 | <Price> | Rejected | Rejected  | 0.0     | NaN    | 4.0       | 0.0    | NaN   | <text> |
    And no market data snapshot for 912828Q45 is sent

    Examples:
      | TimeInForce | tif     | Price | PegPriceType | PegRoundDirection | PegOffsetValue | PegOffsetType | PegScope | text                                                   |
      | 0           | DAY     |       | 1            |                   |                |               |          | PegPriceType 1 is not supported                        |
      | 0           | DAY     |       |              | 3                 |                |               |          | PegRoundDirection 3 is not supported                   |
      | 0           | DAY     |       |              |                   | 1              | 3             |          | PegOffsetType 3 is not supported                       |
      | 0           | DAY     |       |              |                   |                |               | 2        | PegScope 2 is not supported                            |
      | 0           | DAY     | 100.3 |              |                   |                |               |          | Price 100.3 does not align to minPriceIncrement of 0.5 |
      | 7           | AtClose |       |              |                   |                |               |          | Pegged orders are only accepted in the continuous book |


  Scenario: NewOrderSingle FIX message - the peg instructions of an order that is not pegged are ignored
    When a NewOrderSingle FIX message is received
      | Username | ClOrdID | Symbol    | OrdType | TimeInForce | Side | OrderQty | MaxShow | Price | PegPriceType | PegOffsetValue | PegScope |
      | id1      | 00001-0 | 912828Q45 | 2       | 0           | 1    | 5.0      | 5.0     | 100.0 | 4            | 3              | 2        |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0 | bid0  | ask0  | askQ0 |
      | 5.0   | 100.0 | NaN   | 0.0   |


  Scenario: OrderCancelReplaceRequest and OrderCancelRequest FIX messages - the Price of a pegged order is optional
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 99.5  |
    Then order 3 is pegged at 99.5

  # no Price in the message: the order has no cap anymore
    When an OrderCancelReplaceRequest FIX message is received
      | Username | OrigClOrdID | OrderID | ClOrdID | Symbol    | OrdType | TimeInForce | Side | OrderQty | MaxShow | Price |
      | id3      | 00003-0     | 3       | 00003-1 | 912828Q45 | P       | 0           | 1    | 6.0      | 6.0     |       |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id3 |     3 | 00003-1 | 912828Q45 | Pegged  | DAY | Buy  | 6.0      | 6.0 | NaN   | Replaced | Replaced  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      | 100.0    |                   |
      | id3 |     3 | 00003-1 | 912828Q45 | Pegged  | DAY | Buy  | 6.0      | 6.0  | 100.0 | Restated | New             | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      | 100.0    | 3                 |
    And order 3 is pegged at 100.0
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 0.0   | NaN   | 11.0  | 100.0 | 103.0 | 5.0   |

  # a Price in the message: it is the new cap
    When an OrderCancelReplaceRequest FIX message is received
      | Username | OrigClOrdID | OrderID | ClOrdID | Symbol    | OrdType | TimeInForce | Side | OrderQty | MaxShow | Price |
      | id3      | 00003-1     | 3       | 00003-2 | 912828Q45 | P       | 0           | 1    | 6.0      | 6.0     | 99.0  |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id3 |     3 | 00003-2 | 912828Q45 | Pegged  | DAY | Buy  | 6.0      | 6.0 | 99.0  | Replaced | Replaced  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      | 99.0     |                   |
      | id3 |     3 | 00003-2 | 912828Q45 | Pegged  | DAY | Buy  | 6.0      | 6.0  | 99.0  | Restated | New             | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      | 99.0     | 3                 |
    And order 3 is pegged at 99.0

  # an OrdType that is not Pegged: the request is rejected
    When an OrderCancelReplaceRequest FIX message is received
      | Username | OrigClOrdID | OrderID | ClOrdID | Symbol    | OrdType | TimeInForce | Side | OrderQty | MaxShow | Price |
      | id3      | 00003-2     | 3       | 00003-3 | 912828Q45 | 2       | 0           | 1    | 6.0      | 6.0     | 99.0  |
    Then all rejections sent back to clients are
      | uid | ordId | clOrdId | ordStatus | text                                   |
      | id3 |     3 | 00003-3 | Rejected  | Cannot amend to or from a Pegged order |

    When an OrderCancelRequest FIX message is received
      | Username | OrigClOrdID | OrderID | ClOrdID | Symbol    | Side | OrderQty |
      | id3      | 00003-2     | 3       | 00003-4 | 912828Q45 | 1    | 6.0      |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx |
      | id3 |     3 | 00003-4 | 912828Q45 | Pegged  | DAY | Buy  | 6.0      | 6.0 | 99.0  | Canceled | Canceled  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      | 99.0     |
    And order 3 is not active


  Scenario: A pegged order sent by an exchange client carries its peg instructions
    Given the following orders were received earlier
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | Buy  | 5.0      | 5.0 | 100.0 |
      | id2 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | Sell | 5.0      | 5.0 | 103.0 |

    When a new order is sent by an exchange client
      | uid | secId     | ordId | clOrdId | ordType | tif | side | shownQty | qty | price | pegPriceType | pegOffsetValue | pegOffsetType | pegRoundDirection | pegScope |
      | id3 | 912828Q45 |     3 | 00003-0 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 102.0 | Market       | -0.7           | Price         | MoreAggressive    | Local    |
      | id4 | 912828Q45 |     4 | 00004-0 | Pegged  | DAY | Sell | 3.0      | 3.0 |       |              |                |               |                   |          |
      | id5 | 912828Q45 |     5 | 00005-0 | Limit   | DAY | Buy  | 2.0      | 2.0 | 99.0  |              |                |               |                   |          |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text | peggedPx | restatementReason |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0 | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | 102.0    |                   |
      | id3 |     3 | 00003-0 | 912828Q45 | Pegged  | DAY | Buy  | 4.0      | 4.0  | 102.0 | Restated | New             | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      | 102.0    | 3                 |
      | id4 |     4 | 00004-0 | 912828Q45 | Pegged  | DAY | Sell | 3.0      | 3.0 | NaN   | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      | 103.0    |                   |
      | id5 |     5 | 00005-0 | 912828Q45 | Limit   | DAY | Buy  | 2.0      | 2.0 | 99.0  | New      | New       | 0.0     | NaN    | 2.0       | 0.0    | NaN   |      |          |                   |
    And order 3 is pegged at 102.0
    And order 4 is pegged at 103.0
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2 | bid2  | bidQ1 | bid1  | bidQ0 | bid0  | ask0  | askQ0 |
      | 2.0   | 99.0  | 5.0   | 100.0 | 4.0   | 102.0 | 103.0 | 8.0   |
