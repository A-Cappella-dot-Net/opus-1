package net.a_cappella.cembalo;

import net.a_cappella.cembalo.constants.Side;

@FunctionalInterface
public interface SummarizedOrdersConsumer {
    void accept(double price, Side side, SummarizedOrders summarizedOrders);
}
