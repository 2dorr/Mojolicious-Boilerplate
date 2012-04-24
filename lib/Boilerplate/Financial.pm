package Financial;

use strict;
use warnings;

use Math::Financial;
use Data::Printer;
use Data::Dumper;
use Perl6::Say;

sub get_assets_value {
  my $month = shift;
  my $start_config = shift;

  $month->{assets_value} = $month->{num_aps} * $start_config->{apartment_value} + $month->{cash} - $month->{debt};
  $month->{total_possible_credit} = ( 1 + $start_config->{percent_from_assured} / 100 ) * $month->{assets_value};

  my $calc = new Math::Financial(
    ir  => $start_config->{credit_interest_rate},
    pmt => $month->{total_to_invest},
    np  => $start_config->{max_months_per_credit},

  );

  $month->{max_credit_on_time} = $calc->loan_size();

  return $month;
}   ## --- end sub get_assets_value

sub buy_aps {

  my $month = shift;
  my $start_config = shift;
  
  $month->{assets_value} = $month->{num_aps} * $start_config->{apartment_value} + $month->{cash} - $month->{debt};
  $month->{total_possible_credit} = ( 1 + $start_config->{percent_from_assured} / 100 ) * $month->{assets_value};

  my $calc = new Math::Financial(
    ir  => $start_config->{credit_interest_rate},
    pmt => $month->{total_to_invest},
    np  => $start_config->{max_months_per_credit},
  );

  $month->{max_credit_on_time} = $calc->loan_size();

  if ( $month->{max_credit_on_time} + $month->{cash} >= $start_config->{apartment_value}
    && $month->{total_possible_credit} + $month->{cash} >= $month->{max_credit_on_time} )
  {

    my $aps_to_buy = int( ( $month->{max_credit_on_time} + $month->{cash} ) / $start_config->{apartment_value} );

    $month->{credit} = $start_config->{apartment_value} * $aps_to_buy - $month->{cash};

    my $calc_period = new Math::Financial(
      ir  => $start_config->{credit_interest_rate},
      pmt => $month->{total_to_invest},
      pv  => $month->{credit},
    );

    $month->{debt} = int( $calc_period->loan_term() * $month->{total_to_invest} + 0.5 );
    $month->{cash} = 0;

    $month->{num_aps} += $aps_to_buy;
  }

  return $month;
}    ## --- end sub buy_aps

sub next_month_stats {
  my $month_object = shift;
  my $start_config = shift;
  my $monthly_taxes       = $start_config->{annual_taxes} / 12;
  my $monthly_reparations = $start_config->{annual_reparations} / 12;

  if ( $month_object->{debt} > 0 ) {
    $month_object->{debt} -= $month_object->{total_to_invest};

    if ( $month_object->{debt} < 0 ) {
      $month_object->{cash} += -1 * $month_object->{debt};
      $month_object->{debt} = 0;
    }
    return $month_object;
  }

  $month_object->{cash} += $month_object->{total_to_invest};

  if ( $month_object->{cash} >= $start_config->{down_payment} ) {

    $month_object->{num_aps} += 1;

    #               $month_object = buy_aps( $month_object );
    $month_object->{total_to_invest} =
      $start_config->{monthly_investment}
      + ( $month_object->{num_aps} * ( $start_config->{monthly_rent} - $monthly_taxes - $monthly_reparations ) );

    while ( $month_object->{cash} > $start_config->{apartment_value} ) {
      $month_object->{cash} -= $start_config->{apartment_value};
      $month_object->{num_aps} += 1;
    }

    $month_object->{credit_value} = $start_config->{apartment_value} - $month_object->{cash};

    my $calc = new Math::Financial(
      pv  => $month_object->{credit_value},
      ir  => $start_config->{credit_interest_rate},
      pmt => $month_object->{total_to_invest},
    );

    #say $calc->loan_term();
    say $month_object->{total_to_invest};
    $month_object->{debt} = int( $calc->loan_term() * $month_object->{total_to_invest} + 0.5 );
    $month_object->{cash} = 0;
  }

  return $month_object;
} 


1;