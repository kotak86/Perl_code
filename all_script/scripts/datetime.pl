use DateTime;

  $dt = DateTime->new(
      year       => 1964,
      month      => 10,
      day        => 16,
      hour       => 16,
      minute     => 12,
      second     => 47,
      nanosecond => 500000000,
      time_zone  => 'Asia/Taipei',
  );

  print "The \$dt is $dt\n";
#  $dt = DateTime->from_epoch( epoch => $epoch );

  print "Now The \$dt is $dt\n";
  $dt = DateTime->now; # same as ( epoch => time() )


  print "Now The \$dt is $dt\n";
  $year   = $dt->year;
  $month  = $dt->month;          # 1-12

  $day    = $dt->day;            # 1-31

  $dow    = $dt->day_of_week;    # 1-7 (Monday is 1)

  $hour   = $dt->hour;           # 0-23
  $minute = $dt->minute;         # 0-59

  $second = $dt->second;         # 0-61 (leap seconds!)

  $doy    = $dt->day_of_year;    # 1-366 (leap years)

  $doq    = $dt->day_of_quarter; # 1..

  $qtr    = $dt->quarter;        # 1-4

  # all of the start-at-1 methods above have corresponding start-at-0
  # methods, such as $dt->day_of_month_0, $dt->month_0 and so on

  $ymd    = $dt->ymd;           # 2002-12-06
  $ymd    = $dt->ymd('/');      # 2002/12/06

  $mdy    = $dt->mdy;           # 12-06-2002
  $mdy    = $dt->mdy('/');      # 12/06/2002

  $dmy    = $dt->dmy;           # 06-12-2002
  $dmy    = $dt->dmy('/');      # 06/12/2002

  $hms    = $dt->hms;           # 14:02:29
  $hms    = $dt->hms('!');      # 14!02!29

  $is_leap  = $dt->is_leap_year;

  # these are localizable, see Locales section
  $month_name  = $dt->month_name; # January, February, ...
  $month_abbr  = $dt->month_abbr; # Jan, Feb, ...
  $day_name    = $dt->day_name;   # Monday, Tuesday, ...
  $day_abbr    = $dt->day_abbr;   # Mon, Tue, ...

  # May not work for all possible datetime, see the docs on this
  # method for more details.
  $epoch_time  = $dt->epoch;
 print"This is \$epoch_time $epoch_time"; 
  $dt2 = $dt + $duration_object;

  $dt3 = $dt - $duration_object;

  $duration_object = $dt - $dt2;

  $dt->set( year => 1882 );

  $dt->set_time_zone( 'America/Chicago' );

  $dt->set_formatter( $formatter );
