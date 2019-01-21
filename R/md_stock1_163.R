
#' @import data.table 
#' @importFrom jsonlite fromJSON
md_stock_spotall_163 = function(symbol = "a,index", only_symbol = FALSE) {
  tags = market = exchange = time = . = submarket = region = board = name = NULL
    
  fun_stock_163 = function(urli, mkt) {
    code = symbol = exchange = . = name = high = low = price = yestclose = updown = percent = hs = volume = turnover = mcap = tcap = pe = mfsum = net_income = revenue = plate_ids = time = NULL
    # stock
    # c("code", "five_minute" "high", "hs", "lb", "low", "mcap", "mfratio", "mfsum", "name", "open", "pe", "percent", "plate_ids", "price", "sname", "symbol", "tcap", "turnover", "updown", "volume", "wb", "yestclose", "zf", "no", "announmt", "uvsnews")
    # index
    # c("code", "high", "low", "name", "open" "percent", "price", "symbol", "time", "turnover" "updown", "volume", "yestclose", "no", "zhenfu") 
    
    jsonDat = fromJSON(urli)
    
    jsonDF = jsonDat$list
    if (mkt == "stock") {
      jsonDF$net_income = jsonDF$MFRATIO$MFRATIO2
      jsonDF$revenue = jsonDF$MFRATIO$MFRATIO10
      jsonDF[,c("MFRATIO", "UVSNEWS","ANNOUNMT","NO")] = NULL 
      names(jsonDF) = tolower(names(jsonDF))
      
      jsonDF = setDT(jsonDF)[,`:=`(
        date = as.Date(substr(jsonDat$time,1,10)), 
        time = jsonDat$time#,
        #strptime(jsonDat$time, "%Y-%m-%d %H:%M:%S", tz = "Asia/Shanghai")
      )][, .(date, symbol, name, open, high, low, close=price, prev_close=yestclose, change=updown, change_pct=percent*100, volume, amount=turnover, turnover=hs*100, cap_market=mcap, cap_total=tcap, pe_last=pe, eps=mfsum, net_income, revenue, plate_ids, time=as.POSIXct(time))]
    } else if (mkt == "index") {
      names(jsonDF) = tolower(names(jsonDF))
      
      jsonDF = setDT(jsonDF)[,`:=`(
        date = as.Date(substr(jsonDat$time,1,10))
      )][, .(date, symbol, name, open, high, low, close=price, prev_close=yestclose, change=updown, change_pct=percent*100, volume, amount=turnover, time=as.POSIXct(time))]
    }
    
    return(jsonDF[, `:=`(market = mkt, region = "cn")])
  }
  
  urls_163 = list(
    a = "http://quotes.money.163.com/hs/service/diyrank.php?host=http%3A%2F%2Fquotes.money.163.com%2Fhs%2Fservice%2Fdiyrank.php&page=0&query=STYPE%3AEQA&fields=NO%2CSYMBOL%2CNAME%2CPLATE_IDS%2CPRICE%2CPERCENT%2CUPDOWN%2CFIVE_MINUTE%2COPEN%2CYESTCLOSE%2CHIGH%2CLOW%2CVOLUME%2CTURNOVER%2CHS%2CLB%2CWB%2CZF%2CPE%2CMCAP%2CTCAP%2CMFSUM%2CMFRATIO.MFRATIO2%2CMFRATIO.MFRATIO10%2CSNAME%2CCODE%2CANNOUNMT%2CUVSNEWS&sort=CODE&order=desc&count=100000&type=query", 
    b = "http://quotes.money.163.com/hs/service/diyrank.php?host=http%3A%2F%2Fquotes.money.163.com%2Fhs%2Fservice%2Fdiyrank.php&page=0&query=STYPE%3AEQB&fields=NO%2CSYMBOL%2CNAME%2CPLATE_IDS%2CPRICE%2CPERCENT%2CUPDOWN%2CFIVE_MINUTE%2COPEN%2CYESTCLOSE%2CHIGH%2CLOW%2CVOLUME%2CTURNOVER%2CHS%2CLB%2CWB%2CZF%2CPE%2CMCAP%2CTCAP%2CMFSUM%2CMFRATIO.MFRATIO2%2CMFRATIO.MFRATIO10%2CSNAME%2CCODE%2CANNOUNMT%2CUVSNEWS&sort=PERCENT&order=desc&count=100000&type=query",
    index = "http://quotes.money.163.com/hs/service/hsindexrank.php?host=/hs/service/hsindexrank.php&page=0&query=IS_INDEX:true;EXCHANGE:CNSESH&fields=no,TIME,SYMBOL,NAME,PRICE,UPDOWN,PERCENT,zhenfu,VOLUME,TURNOVER,YESTCLOSE,OPEN,HIGH,LOW&sort=SYMBOL&order=asc&count=10000&type=query",
    index = "http://quotes.money.163.com/hs/service/hsindexrank.php?host=/hs/service/hsindexrank.php&page=0&query=IS_INDEX:true;EXCHANGE:CNSESZ&fields=no,TIME,SYMBOL,NAME,PRICE,UPDOWN,PERCENT,zhenfu,VOLUME,TURNOVER,YESTCLOSE,OPEN,HIGH,LOW&sort=SYMBOL&order=asc&count=10000&type=query"
  )
  idx = which(names(urls_163) %in% unlist(strsplit(symbol,",")))
  
  df_stock_cn = rbindlist(mapply(
    fun_stock_163, urls_163[idx], c("stock","stock","index","index")[idx], SIMPLIFY = FALSE
  ), fill = TRUE)
  
  # date time of download
  datetime = gsub("[^(0-9)]","",df_stock_cn[1,time])
  if (df_stock_cn[1,time] < as.POSIXct(paste(df_stock_cn[1,date], "15:00:00"))) 
    cat("The close price is spot price at", as.character(datetime), "\n")
  
  
  if (only_symbol) {
    df_stock_cn = df_stock_cn[
      , tags := mapply(tags_symbol_stockcn, symbol, market)
    ][, c("exchange","submarket","board"):=tstrsplit(tags,",")
    ][, tags := NULL
    ][order(-market, exchange, symbol)
    ][, .(market, submarket, region, exchange, board, symbol, name)]
  } else {
    df_stock_cn = df_stock_cn[, c("market", "region") := NULL]
      
    if (symbol != "index") df_stock_cn = df_stock_cn[, c("plate_ids", "eps", "net_income", "revenue") := NULL]
  }
  
  
  return(df_stock_cn)
}


# query spot data from tx
md_stock_spot1_tx = function(symbol1) {
  dat = doc = . = name = high = low = prev_close = change = change_pct = volume = amount = turnover = cap_market = cap_total = time = symbol = NULL
  
  syb = sapply(symbol1, check_symbol_for_tx)
  dt = readLines(sprintf("http://qt.gtimg.cn/q=%s", paste0(syb, collapse=",")))
  # ff_ 资金流量 # s_pk 盘口 # s_ 简要信息
  
  dt = data.table(
    doc = dt
  )[, doc := iconv(doc, "GB18030", "UTF-8")
    ][, doc := sub(".+=\"\\d+~(.+)\".+", "\\1", doc)
      ][, tstrsplit(doc, "~")]
  
  # colnames_cn = c("名字", "代码", "当前价格", "昨收", "今开", 
  #   "成交量（手）", "外盘", "内盘", 
  #   "买一", "买一量（手）", "买二","买二","买三","买三","买四","买四","买五","买五", 
  #   "卖一", "卖一量", "卖二","卖二","卖三","卖三","卖四","卖四","卖五","卖五", 
  #   "最近逐笔成交", "时间", "涨跌", "涨跌%", "最高", "最低", 
  #   "价格/成交量(手)/成交额", "成交量(手)", "成交额(万)", "换手率", 
  #   "市盈率(TTM)", "", "最高", "最低", "振幅", "流通市值", "总市值", "市净率", "涨停价", "跌停价", "量比", "", "均价", "市盈率(动)", "市盈率(静)")
  
  colnames_en = c("name", "symbol", "close", "prev_close", "open",
                  "volume", "buy", "sell", 
                  "bid1", "bid1_volume", "bid2", "bid2_volume", "bid3", "bid3_volume", "bid4", "bid4_volume", "bid5", "bid5_volume",
                  "ask1", "ask1_volume", "ask2", "ask2_volume", "ask3", "ask3_volume", "ask4", "ask4_volume", "ask5", "ask5_volume",
                  "last_trade", "date", "change", "change_pct", "high", "low", 
                  "", "volume", "amount", "turnover", 
                  "pe_trailing", "", "high", "low", "", "cap_market", "cap_total", "pb", "", "", "", "", "average", "pe_forward", "pe_last" )
  if (ncol(dt) == 52) dt$V53 = ''
  setnames(dt, colnames_en)
  
  num_cols = c(
    "open", "high", "low", "close", "prev_close", "change", "change_pct", "volume", "amount", "turnover", "cap_market", "cap_total", "pb", "pe_last", "pe_trailing", "pe_forward"
  )
  dt = dt[,.(
    date, symbol, name, open, high, low, close, prev_close, change, change_pct, volume, amount, turnover, cap_market, cap_total, pb, pe_last, pe_trailing, pe_forward#, 
    #buy, sell, 
    #bid1, bid1_volume, bid2, bid2_volume, bid3, bid3_volume, bid4, bid4_volume, bid5, bid5_volume, 
    #ask1, ask1_volume, ask2, ask2_volume, ask3, ask3_volume, ask4, ask4_volume, ask5, ask5_volume
    )][, (num_cols) := lapply(.SD, as.numeric), .SDcols= num_cols
     ][, `:=`(
       volume = volume*100,
       amount = amount*10000,
       cap_market = cap_market*10^8, 
       cap_total = cap_total*10^8,
       time = as.POSIXct(date, format="%Y%m%d%H%M%S", tz="Asia/Shanghai"),
       date = as.Date(date, format="%Y%m%d%H%M%S")
     )]
  
  if (dt[1,time] < as.POSIXct(paste(dt[1,date], '15:00:00')))
    cat("The close price is spot price at", dt[1,as.character(time)], "\n")
  
  return(dt)
}


#' @import data.table
#' @importFrom readr read_csv locale col_date col_character col_double col_integer
md_stock_hist1_163 = function(symbol1, from="1900-01-01", to=Sys.Date(), fillzero=FALSE) {
  change_pct = symbol = NULL
  # http://quotes.money.163.com/service/chddata.html?code=0000001&start=19901219&end=20180615&fields=TCLOSE;HIGH;LOW;TOPEN;LCLOSE;CHG;PCHG;VOTURNOVER;VATURNOVER
  # http://quotes.money.163.com/service/chddata.html?code=1399001&start=19910403&end=20180615&fields=TCLOSE;HIGH;LOW;TOPEN;LCLOSE;CHG;PCHG;VOTURNOVER;VATURNOVER
  # https://query1.finance.yahoo.com/v7/finance/download/^SSEC?period1=1526631424&period2=1529309824&interval=1d&events=history&crumb=mO08ZCtWRMI
  
  # "http://api.finance.ifeng.com/akmonthly/?code=sh600000&type=last"
  # {'D': 'akdaily', 'W': 'akweekly', 'M': 'akmonthly'}
  
  # symbol
  syb = check_symbol_for_163(symbol1)

  # date range
  fromto = lapply(list(from=from,to=to), function(x) format(check_fromto(x), "%Y%m%d"))
  
  # create link
  link = paste0("http://quotes.money.163.com/service/chddata.html?code=",syb,"&start=",fromto$from,"&end=",fromto$to,"&fields=TOPEN;HIGH;LOW;TCLOSE;LCLOSE;CHG;PCHG;VOTURNOVER;VATURNOVER;TURNOVER;MCAP;TCAP")
  # 开盘价   # TOPEN:       open
  # 最高价   # HIGH:        high
  # 最低价   # LOW:         low
  # 收盘价   # TCLOSE:      close
             # LCLOSE:      last close
  # 涨跌额   # CHG:         chg
  # 涨跌幅   # PCHG:        chg percent
  # 成交量   # VOTURNOVER:  volume turnover
  # 成交金额 # VATURNOVER:  amount turnover
  # 换手率   # TURNOVER:    turnour
  # 流通市值 # MCAP:        tradable market capitalisation
  # 总市值   # TCAP:        total market capitalisation
             
   
  
  # download data from 163
  dt <- read_csv(
    file=link, locale = locale(encoding = "GBK"), na=c("", "NA", "None"),
    col_types=list(col_date(format = ""), col_character(), col_character(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double(), col_double()))
  # dt <- load_read_csv(link, "GBK")
  
  # set names of datatable
  cols_name = c("date", "symbol", "name", "open", "high", "low", "close", "prev_close", "change", "change_pct", "volume", "amount", "turnover", "cap_market", "cap_total")
  setnames(dt, cols_name)
  
  
  # if (max(dt[["date"]]) < lwd()) dt = rbindlist(list(dt, md_stock_spot1_tx(symbol1)[,names(dt), with=FALSE]), fill = FALSE)
  dt = setDT(dt, key="date")[, symbol := symbol1][, (cols_name), with=FALSE]
  if (max(dt[["date"]]) < lwd()) dt = unique(dt, by="date")
  
  # fill zeros in dt
  if (fillzero) {
    cols_name = c("open", "high", "low", "close")
    dt = dt[, (cols_name) := lapply(.SD, fill0), .SDcols = cols_name]
  }
  
  return(dt)
}


#' @import data.table
md_stock_163 = function(symbol, from="1900-01-01", to=Sys.Date(), print_step=1L, freq = "daily", fillzero=FALSE, ...) {
  # fromt to 
  from = check_fromto(from)
  to = check_fromto(to)
  
  # frequency
  freq = check_arg(freq, c("daily"))
  
  # query data
  if (from==Sys.Date()) {
    if (all(unlist(strsplit(symbol,",")) %in% c('a','b','index'))) {
      fuc = 'md_stock_spotall_163'
    } else {
      fuc = 'md_stock_spot1_tx'
    }
    
    dat_list <- try(do.call(fuc, args=list(symbol=symbol)), silent = TRUE)
    return(dat_list)
    
  } else {
    dat_list = load_dat_loop(symbol, "md_stock_hist1_163", args = list(from = from, to = to, fillzero = fillzero), print_step=print_step)
    return(dat_list)
  }
}

