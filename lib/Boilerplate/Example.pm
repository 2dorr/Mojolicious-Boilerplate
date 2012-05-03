package Boilerplate::Example;
use Mojo::Base 'Mojolicious::Controller';

use strict;
use warnings;
use utf8;

use Perl6::Say;
use Data::Printer;
use DateTime;
use DateTime::Format::HTTP;
use Data::Dumper;

use Boilerplate::Financial;

sub welcome {
  my $self = shift;

  push @{ $self->session->{error_messages} },  'You have to login to proceed!!' if !defined $self->session->{user};  

  # Render template "example/welcome.html.ep" with message
  $self->render(
    message => 'Use this project as a way to quick start any new project!!');
}

sub login {
  my $self = shift;
  
  $self->session->{user} = $self->_get_a_user();

  push @{ $self->session->{success_messages} },  'Congratulations, you have successfully logged in.' ;
  push @{ $self->session->{notice_messages} }, sprintf('Welcome %s %s.', $self->session->{user}->{first_name}, $self->session->{user}->{last_name} );

  $self->redirect_to('/');
}


sub logout{
  my $self = shift;

  $self->session( expires => 1);

  $self->redirect_to('/');
}

sub about{
  my $self = shift;

}

sub signed_in_about{
  my $self = shift;
  
  $self->render( {
    template  => 'example/about',
    user_type => $self->param('user_type'),
  } );
}

sub signed_in_menu{
  my $self = shift;
  
  $self->render( {
    template  => 'example/menu_page',
    user_type => $self->param('user_type'),
  } );
}

sub finance {
  my $self = shift;
  
  my @arr_params = $self->param();
  my %input_params = map{ $_ => $self->param($_); } @arr_params if( scalar( @arr_params ) );
  my $start_config = \%input_params;
  my $months = [];
  my $month  = {
    num_aps         => $start_config->{start_aparments_no},
    total_to_invest => $start_config->{monthly_investment}
      + $start_config->{start_aparments_no} * $start_config->{monthly_rent},
    cash => $start_config->{start_cash},
    debt => $start_config->{initial_debt},
  };
  
  my $i           = 0;
  my $result = { string => {} };
  my $old_num_aps = $start_config->{num_aps};
  my $prev_debt   = 0;
  while ( $i < $start_config->{total_months} ) {
  
    $month = Boilerplate::Financial::next_month_stats($month, $start_config);
    die "Error in month $i" . p($month) if ( $month->{debt} < 0 or $month->{credit_value} < 0 );
    $month = Boilerplate::Financial::get_assets_value($month, $start_config) and say "month $i:" . p($month) if $old_num_aps != $month->{num_aps};
    my %local_month = %$month;          
    push( @{$months}, \%local_month );
    say "apartment no:" . $month->{num_aps} . " paid in month no: $i" if $prev_debt > 0 && $month->{debt} == 0;
    $old_num_aps = $month->{num_aps};
    $prev_debt   = $month->{debt};
  
    $start_config->{apartment_value} *= ( 1 + ( $start_config->{apartment_appreciation} / 100 ) / 12 );
    $start_config->{monthly_rent}    *= ( 1 + ( $start_config->{yearly_rent_increase} / 100 ) / 12 );
    $i++;
  }
  
  my $display_data = [];
  my $display_apps = [];
  my $display_money_data = [];
  my $dt = DateTime->now();
  my $total_invested = 0;
  my $current_date = 0;
  foreach my $row ( @$months ) {
    $total_invested += $start_config->{monthly_investment};
    $current_date = $dt->add(months => 1)->year;
    push @$display_apps, [ $current_date, $row->{num_aps} ];
    push @$display_data, [ $current_date, $total_invested ];
    push @$display_money_data, [ $current_date, $row->{debt}, $row->{assets_value}, $row->{max_credit_on_time}, $row->{total_possible_credit}, $row->{cash} ];
  }
  $self->render( {
    template           => 'example/finance',
    math               => $months,
    display_apps       => $display_apps,
    display_data       => $display_data,
    display_money_data => $display_money_data,
  } );

}

sub _get_a_user {
  my $self = shift;

  #randomly get a user from config
  return $self->app->{config}->{demo_users}->{ ( keys %{ $self->app->{config}->{demo_users} } )[ rand( scalar( keys %{ $self->app->{config}->{demo_users} } ) ) ] };
}

1;
