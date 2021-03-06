package CLDL::Helpers::Dataviews;

use Moo;

use Dancer2;
use Dancer2::Plugin::Database;

our $VERSION = '0.00001';


# SQL statements
my $SQL_LIB = {
     DVF => 
         qq( SELECT dvf_id, 
                    ordr,
                    dvf_db_column,
                    dvf_name,
                    dvf_label, 
                    dvf_type,
                    dvf_key,
                    dvf_placeholder,
                    dvf_help,
                    dvf_sortable,
                    dvf_sort_ordr,
                    dvf_sort_asc_desc,
                    d_id,
                    dvf_js_functions,
                    dvf_data_attributes
               FROM cldl_dvf 
                 WHERE dv_id      = ?
                       AND active = 1 
                   ORDER BY ordr  ),
     D => 
         qq( SELECT d_id, 
                    d_name
               FROM cldl_d
                 WHERE d_id           = ? 
                       AND (    company_id = ? 
                             OR company_id = 1 )
                       AND active     = 1 ),
     DF => 
         qq( SELECT df_id, 
                    ordr,
                    df_label,
                    df_value,
                    df_default
               FROM cldl_df 
                 WHERE d_id       = ?
                       AND active = 1 
                   ORDER BY ordr  ),
     DF_DT => 
         qq( SELECT df_label
               FROM cldl_d d,
                    cldl_df df
                 WHERE d.d_id           = ? 
                       AND (    d.company_id = ? 
                             OR d.company_id = 1 )
                       AND d.active     = 1 

                       AND df.df_value  = ?
                       AND df.d_id      = d.d_id 
                       AND df.active    = 1  ),
     DF_DT =>
         qq( SELECT df_label
               FROM cldl_d d,
                    cldl_df df
                 WHERE d.d_id           = ? 
                       AND (    d.company_id = ? 
                             OR d.company_id = 1 )
                       AND d.active     = 1 

                       AND df.df_value  = ?
                       AND df.d_id      = d.d_id 
                       AND df.active    = 1  ),
     MENU => qq( 
                SELECT menu_id,
                       ordr,
                       menu_label,
                       menu_link,
                       menu_js_functions,
                       menu_data_attributes,
                       menu_notes
                  FROM cldl_menu
                    WHERE (    company_id = ?
                            OR company_id = 1 )
                          AND pmenu_id IS NULL
                          AND active   = 1
                  UNION
                SELECT pmenu_id AS menu_id,
                       ordr,
                       menu_label,
                       menu_link,
                       menu_js_functions,
                       menu_data_attributes,
                       menu_notes
                  FROM cldl_menu
                    WHERE (    company_id = ?
                            OR company_id = 1 )
                          AND pmenu_id IS NOT NULL
                          AND active   = 1
                   ORDER BY menu_id, ordr ),
};


# Return an array of table names
sub tables {
    my @tbl;

    my @table_list = database->tables('', '', '', 'TABLE');

    for my $table ( @table_list) {
      $table =~ s/`//g;
      my @tmp_tbl = split( /\./, $table);
      push @tbl, $tmp_tbl[1];
    }

    return @tbl;
}

sub formdatalists {
  my $dvf_d_id   = shift;
  my $company_id = shift;

  my $d = {};

  # DataView Field Values ( checkbox, radio, select)
  my $sth_d  = database->prepare( $SQL_LIB->{D}  );
  my $sth_df = database->prepare( $SQL_LIB->{DF} );

  foreach my $skey ( keys %{$dvf_d_id} ) { # skey   = field name (s=search)
    my $s_d_id = $dvf_d_id->{ $skey };     # s_d_id = key to data(s=search)
    $sth_d->execute( $s_d_id, $company_id );
    $d->{ $s_d_id } = $sth_d->fetchrow_hashref ;

    my @d_fields = ();
    $sth_df->execute( $s_d_id );
    while ( my $d_ref = $sth_df->fetchrow_hashref ) {
      push( @d_fields, $d_ref);
    }
    $d->{ $s_d_id }->{dtl} = \@d_fields;
  }

  return $d;
}

sub selectedvalue {
  my $ref        = shift;
  my $dvf_d_id   = shift;
  my $company_id = shift;

  my $sth_df_dt  = database->prepare( $SQL_LIB->{DF_DT}  );

  # loop through each field and see if there's a lookup value for it
  #   if there is, then get it's value from the DB
  foreach my $skey ( keys %{$ref} ) {

    # Grab unique keys for lookup
    if ( defined $dvf_d_id->{ $skey } ) {

      $sth_df_dt->execute( $dvf_d_id->{ $skey }, 
                           $company_id, 
                           $ref->{ $skey } );

      my $tmp_ref = $sth_df_dt->fetchrow_hashref ;
      $ref->{ $skey } = $tmp_ref->{df_label};
    }
  }

  return $ref;
}

sub menu {
  my $company_id = shift;
  my $menu;

  my $sth_menu = database->prepare( $SQL_LIB->{MENU} );

  $sth_menu->execute( $company_id, $company_id );

  while ( my $ref = $sth_menu->fetchrow_hashref ) {
    push( @{$menu}, $ref);
  }  

  return $menu;

}



1;
