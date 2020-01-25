use "textio.eh"
use "io.eh"
use "dict.eh"
use "string.eh"
use "strbuf.eh"
use "mint/dialog.eh"
use "ui.eh"
use "list.eh"
use "form.eh"
use "sys.eh"
use "time.eh"

const VERSION = "2.0"

def load_dict(): Dict {
    var d = new Dict()
    var r = utfreader(fopen_r("/res/jin/table.txt"))
    var t = r.readline()
    var a: [String]
    while (t != null) {
        a = t.split('=')
        d[a[0]] = a[1]
        t = r.readline() }
    r.close()
    d }

def load_kanji(): [Any] {
    var d = new List()
    var r = utfreader(fopen_r("/res/jin/kanji.txt"))
    var t = r.readline()
    var a: [String]
    var b: [String]
    while (t != null) {
        if (t[0] != ';') {
            a = t.split('/')
            b = a[0].split(',')
            d.add(b)
            d.add(a[1]) }
        t = r.readline() }
    r.close()
    d.toarray() }

def check_hiragana(text: String, i: Int): Bool {
    if (text[i].tostr() == text[i].tostr().lcase()) true else false }

def non_translatable(text: String, i: Int): Bool {
    if ("aiueo{}()[]<>,.-\"\' :!?_xkcgszjtdnhbpvfmyrlw".find(text[i].tostr().lcase()) == -1) true else false }

def symbol(text: String, i: Int): Bool {
    if ("{}()[]<>,.-\"\' :!?_".find(text[i].tostr()) >= 0) true else false }

def one_char(text: String, i: Int): Bool {
    if ("aiueo".find(text[i].tostr().lcase()) >= 0) true else false }

def two_char(text: String, i: Int): Bool {
    if ("kcgszjtdnhbpvfmyrlw".find(text[i].tostr().lcase()) >=0 && "aiueo".find(text[i+1].tostr().lcase()) >= 0) true else false }

def three_char(text: String, i: Int): Bool {
    if ("tkgszjcdnhbpmrl".find(text[i].tostr().lcase()) >=0 && "swyh".find(text[i+1].tostr().lcase()) >= 0 && "aiueo".find(text[i+2].tostr().lcase()) >= 0 && text[i] != text[i+1]) true else false }

def small_tsu(text: String, i: Int): Bool {
    if ("tkgszjcdnhbpmrl".find(text[i].tostr().lcase()) == "tkgszjcdnhbpmrl".find(text[i+1].tostr().lcase()) && "tkgszjcdnhbpmrl".find(text[i].tostr().lcase()) >= 0 && "aeioun".find(text[i].tostr().lcase()) == -1) true else false }

def check_kanji(text: String, i: Int): Bool {
    if (text[i]=='|') true else false }

def kanji_end(text: String, i: Int): Int {
    while (text[i] != '|') i+= 1
    i }

def kanji_len(text: String, i: Int): Int {
    var l = 0
    while (text[i+l] != '|') l += 1
    l+1 }

def find_kanji(rom: String, kanji: [Any]): String {
    var ret: String
    var found = new List()
    for (var i=0, i<kanji.len, i+=2) {
        for (var j=0, j<(kanji[i].cast([String])).len, j+=1) {
            if (rom == kanji[i].cast([String])[j]) found.add(i+1) } }
    if (found.len() == 1) {
        ret = kanji[found[0].cast(Int)].cast(String) }
    else if (found.len() > 1) {
        var foundarr = new [String](found.len())
        for (var i=0, i<foundarr.len, i+=1) foundarr[i] = rom + ": " + kanji[found[i].cast(Int)].cast(String) 
        ret = kanji[found[showList("Choose kanji:", foundarr)].cast(Int)].cast(String) }
    else {
            ret = rom }
    ret }

def convert(text: String, table: Dict, kanji: [Any]): String {
    text += "    "
    var dqc = false
    var sqc = false
    var found: String
    var parsed: String
    var res = new StrBuf()
    var hiragana = false
    var err = false
    var i = 0
    var l = text.len()
    while (i<l) {
        hiragana = check_hiragana(text, i)
        if (check_kanji(text, i)) {
            i += 1
            parsed = text[i:kanji_end(text, i)].lcase()
            found = find_kanji(parsed, kanji)
            res.append(found)
            i += kanji_len(text, i) }
        else if (non_translatable(text, i)) {
            res.addch(text[i])
            i += 1 }
        else if (symbol(text, i)) {
            if (text[i] == '\"') {
                if (dqc == false) {
                    res.append(table["\"1"].cast(String)) }
                else {
                    res.append(table["\"2"].cast(String)) }
                dqc = !dqc }
            else if (text[i] == '\'') {
                if (sqc == false) {
                    res.append(table["\'1"].cast(String)) }
                else {
                    res.append(table["\'2"].cast(String)) }
                sqc = !sqc }
            else {
                res.append(table[text[i].tostr()].cast(String)) }
            i += 1 }
        else if (one_char(text, i)) {
            if (hiragana) {
                res.addch(table[text[i].tostr().lcase()].cast(String)[0]-96) }
            else {
                res.addch(table[text[i].tostr().lcase()].cast(String)[0]) }
            i += 1 }
        else if (two_char(text, i)) {
            if (hiragana) {
                if (table[text[i:i+2].lcase()].cast(String).len() == 1) {
                    res.addch(table[text[i:i+2].lcase()].cast(String)[0]-96) }
                else {
                    res.addch(table[text[i:i+2].lcase()].cast(String)[0]-96)
                    res.addch(table[text[i:i+2].lcase()].cast(String)[1]-96) } }
            else {
                if (table[text[i:i+2].lcase()].cast(String).len() == 1) {
                    res.addch(table[text[i:i+2].lcase()].cast(String)[0]) }
                else {
                    res.addch(table[text[i:i+2].lcase()].cast(String)[0])
                    res.addch(table[text[i:i+2].lcase()].cast(String)[1]) } }
            i += 2 }
        else if ("nN".find(text[i].tostr()) >= 0 && "aeiou".find(text[i+1].tostr().lcase()) == -1) {
            if (text[i] == 'n')
                res.addch(table["nn"].cast(String)[0]-96)
            else
                res.append(table["nn"].cast(String))
            i += 1 }
        else if (three_char(text, i)) {
            if (hiragana) {
                if (table[text[i:i+3].lcase()].cast(String).len() == 1) {
                    res.addch(table[text[i:i+3].lcase()].cast(String)[0]-96) }
                else {
                    res.addch(table[text[i:i+3].lcase()].cast(String)[0]-96)
                    res.addch(table[text[i:i+3].lcase()].cast(String)[1]-96) } }
            else {
                if (table[text[i:i+3].lcase()].cast(String).len() == 1) {
                    res.addch(table[text[i:i+3].lcase()].cast(String)[0]) }
                else {
                    res.addch(table[text[i:i+3].lcase()].cast(String)[0])
                    res.addch(table[text[i:i+3].lcase()].cast(String)[1]) } }
            i += 3 }
        else if(small_tsu(text, i)) {
            if (hiragana) {
                res.addch(table["xtsu"].cast(String)[0]-96) }
            else {
                res.addch(table["xtsu"].cast(String)[0]) }
            i += 1 }
        else {
            res.addch(text[i])
            i += 1 } }
    text = res.tostr()
    text = text[0:text.len()-4]
    text }

def main(args: [String]) {
    var load = new Form()
    load.title = "JIn "+VERSION
    load.add(new TextItem("Please wait", "Loading databases..."))
    ui_set_screen(load)
    var table = load_dict()
    var kanji = load_kanji()
    var mainui = new Form()
    mainui.title = "JIn " + VERSION
    var intext = new EditItem("Input:", "", EDIT_ANY, 1000)
    var outtext = new EditItem("Output:", "", EDIT_ANY, 1000)
    mainui.add(intext)
    mainui.add(outtext)
    mainui.add_menu(new Menu("Convert", 0))
    mainui.add_menu(new Menu("Exit", 1))
    ui_set_screen(mainui)
    var c = true
    var r = ""
    var timer = 0
    var ev: UIEvent
    while (c) {
        ev = ui_wait_event()
        while (ev != null) {
            if (ev.kind == EV_MENU) {
                r = ev.value.cast(Menu).text
                if (r == "Convert") outtext.text = convert(intext.text, table, kanji)
                else if (r == "Exit") c = false }
            ev = ui_read_event() } } }