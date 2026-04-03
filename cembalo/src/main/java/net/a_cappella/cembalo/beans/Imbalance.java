/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package net.a_cappella.cembalo.beans;

import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.Side;

public class Imbalance {
    private String _symbol;
    private Book _book;
    private boolean _auction = false;
    private double _price = Double.NaN;
    private double _matched = 0.0;
    private double _surplus = 0.0;
    private Side _side = Side.None;
    private long _tsx;
    private boolean _publishable = false;

    public Imbalance() {}

    public Imbalance(String symbol, Book book) {
        _symbol = symbol;
        _book = book;
    }

    public void reset(String symbol, long tsx) {
        _symbol = symbol;
        _book = null;
        _auction = false;
        _side = null;
        _matched = 0.0;
        _surplus = 0.0;
        _price = Double.NaN;
        _tsx = tsx;
        _publishable = false;
    }

    public void none() {
        set(Side.None, 0.0, 0.0, Double.NaN);
    }

    public void set(Side side, double matched, double surplus, double price) {
        _side = side;
        _matched = matched;
        _surplus = surplus;
        _price = price;
        _tsx = System.currentTimeMillis();
        _publishable = true;
    }

    public void set(Book book, boolean auction, Side side, double matched, double surplus, double price) {
        _book = book;
        _auction = auction;
        _side = side;
        _matched = matched;
        _surplus = surplus;
        _price = price;
        _publishable = true;
    }

    public String getSymbol() {
        return _symbol;
    }
    public Book getBook() {
        return _book;
    }
    public double getPrice() {
        return _price;
    }
    public double getMatched() {
        return _matched;
    }
    public double getSurplus() {
        return _surplus;
    }
    public Side getSide() {
        return _side;
    }
    public long getTsx() {
        return _tsx;
    }

    public void auction() {
        _auction = true;
    }
    public boolean isAuction() {
        return _auction;
    }

    public void notPublishable() {
        _publishable = false;
    }
    public boolean isPublishable() {
        return _publishable;
    }

    @Override
    public String toString() {
        return "{"+_side+" "+_matched+"@"+_price+"}";
    }
}
