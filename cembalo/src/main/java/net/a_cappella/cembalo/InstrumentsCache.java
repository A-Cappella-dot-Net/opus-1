package net.a_cappella.cembalo;

import static net.a_cappella.cembalo.generated.FixConstants.MsgType_SecurityList;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_ContractMultiplier;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_CouponRate;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_LastFragment;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MaturityDate;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MinPriceIncrement;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MinQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MinQtyIncrement;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_NoRelatedSym;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_SecurityID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_SecurityRequestResult;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Symbol;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_TotNoRelatedSym;
import static net.a_cappella.cembalo.generated.FixConstants.Val_LastFragment_Last;
import static net.a_cappella.cembalo.generated.FixConstants.Val_LastFragment_NotLast;
import static net.a_cappella.cembalo.generated.FixConstants.Val_SecurityRequestResult_ValidRequest;

import java.text.ParseException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.BiConsumer;
import java.util.function.Consumer;

import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.a_cappella.cembalo.fix.FixFields;
import net.a_cappella.cembalo.fix.FixMessage;
import net.a_cappella.cembalo.fix.FixRepeatingGroup;

public class InstrumentsCache {
    private static final Logger log = LoggerFactory.getLogger(InstrumentsCache.class);

    private static final int MAX_NUM_SEC_PER_MSG = 4;

    private final List<FixMessage> _securityLists = new ArrayList<>();
    private final Map<String, Instrument> _bySecId = new HashMap<>();

    public InstrumentsCache(String category, List<String> instruments) {
        parseInstruments(category, instruments);
        constructSecurityLists();
    }

    public InstrumentsCache(List<Instrument> instruments) {
        for (Instrument instr : instruments) {
            _bySecId.put(instr.getSecId(), instr);
        }
//		constructSecurityLists();
    }

    public void parseInstruments(String category, List<String> instruments) {
        if ("cash".equals(category)) {
            for (int i = 0; i < instruments.size(); i++) {
                String instrument = instruments.get(i);
                String[] comps = instrument.split("\\|");
                String symbol = comps[0];
                String securityID = comps[1];
                try {
                    double coupon = Double.parseDouble(comps[2]);
                    int maturity = PDate.fromMillis(Utils.parse("MM/dd/yyyy", comps[3]).getTime());
                    double notional = Double.parseDouble(comps[4]);
                    double minQty = Double.parseDouble(comps[5]);
                    double minQtyIncrement = Double.parseDouble(comps[6]);
                    double minPriceIncrement = Double.parseDouble(comps[7]);
                    int ordering = Integer.parseInt(comps[8]);
                    int maxLevels = Integer.parseInt(comps[9]);
                    Bond bond = new Bond(
                            symbol, securityID, minQty, minQtyIncrement, minPriceIncrement, ordering, maxLevels,
                            maturity, notional, coupon
                    );
                    _bySecId.put(symbol, bond);
                } catch (ParseException e) {
                    log.error("", e);
                }
            }
        } else if ("future".equals(category)) {
            for (String instrument : instruments) {
                String[] comps = instrument.split("\\|");
                String bbgSymbol = comps[0];
                String exchSymbol = comps[1];
                try {
                    int maturity = PDate.fromMillis(Utils.parse("MM/dd/yyyy", comps[2]).getTime());
                    int notional = Integer.parseInt(comps[3]);
                    int minQty = Integer.parseInt(comps[4]);
                    int minQtyIncrement = Integer.parseInt(comps[5]);
                    double minPriceIncrement = Double.parseDouble(comps[6]);
                } catch (ParseException e) {
                    log.error("", e);
                }
            }
        } else {
            log.info("Unknown category " + category + ". Skipping...");
        }
    }

    public void constructSecurityLists() {
        FixMessage fixMessage = null;
        FixRepeatingGroup fixRepeatingGroup = null;

        for (Map.Entry<String, Instrument> entry : _bySecId.entrySet()) {
            Instrument instr = entry.getValue();
            if (fixMessage==null) {
                fixMessage = new FixMessage(new FixFields());
                fixMessage.setFixMsgType(MsgType_SecurityList);
                fixRepeatingGroup = new FixRepeatingGroup();
                fixRepeatingGroup._tag = Tag_NoRelatedSym;
                fixMessage.getFields()._repeatingGroups.put(Tag_NoRelatedSym, fixRepeatingGroup);
            }
            FixFields fixFields = fillFields(instr);
            if (fixFields!=null) {
                fixRepeatingGroup._elements.add(fixFields);
                fixRepeatingGroup._numElements++;
                if (fixRepeatingGroup._numElements==MAX_NUM_SEC_PER_MSG) { // one chunk
                    _securityLists.add(fixMessage);
                    fixMessage = null;
                    fixRepeatingGroup = null;
                }
            }
        }
        if (fixMessage!=null) { // remaining entries in the last chunk
            _securityLists.add(fixMessage);
            fixMessage = null;
            fixRepeatingGroup = null;
        }

        int numInstr = 0;
        for (int i=0; i<_securityLists.size(); i++) {
            FixMessage securityList = _securityLists.get(i);
            numInstr += securityList.getFields()._repeatingGroups.get(Tag_NoRelatedSym)._numElements;
        }
        int crtCount = 0;
        for (int i=0; i<_securityLists.size(); i++) {
            FixMessage securityList = _securityLists.get(i);
            FixFields fields = securityList.getFields();
            crtCount += fields._repeatingGroups.get(Tag_NoRelatedSym)._numElements;
            fields.putInt(Tag_TotNoRelatedSym, numInstr);
            fields.putChar(Tag_LastFragment, (crtCount==numInstr)?Val_LastFragment_Last:Val_LastFragment_NotLast);
            fields.putInt(Tag_SecurityRequestResult, Val_SecurityRequestResult_ValidRequest);
        }

        log.info(_securityLists.toString());
    }

    public FixFields fillFields(Instrument instrument) {
        FixFields fixFields = null;
        if (instrument instanceof Bond) {
            Bond bond = (Bond) instrument;
            fixFields = new FixFields();
            fixFields.putString(Tag_Symbol, bond.getSymbol());
            fixFields.putString(Tag_SecurityID, bond.getSecId());
            fixFields.putFloat(Tag_CouponRate, bond.getCoupon());
            fixFields.putInt(Tag_MaturityDate, bond.getMaturityDate());
            fixFields.putFloat(Tag_ContractMultiplier, bond.getContractMultiplier());
            fixFields.putFloat(Tag_MinPriceIncrement, bond.getMinPriceIncrement());
            fixFields.putFloat(Tag_MinQty, bond.getMinQty());
            fixFields.putFloat(Tag_MinQtyIncrement, bond.getMinQtyIncrement());
        } else {

        }
        return fixFields;
    }

    public void forEach(BiConsumer<String, Instrument> action) {
        _bySecId.forEach(action);
    }

    public void forEach(Consumer<FixMessage> action) {
        List<FixMessage> securityLists = _securityLists;
        for (int i = 0; i < securityLists.size(); i++) {
            FixMessage securityList = securityLists.get(i);
            action.accept(securityList);
        }
    }

    public Instrument get(String symbol) {
        return _bySecId.get(symbol);
    }
}
