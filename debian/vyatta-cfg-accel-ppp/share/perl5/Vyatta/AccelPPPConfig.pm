package Vyatta::AccelPPPConfig;

use strict;
use lib "/opt/vyatta/share/perl5";
use Vyatta::Config;
use Vyatta::Misc;
use NetAddr::IP;

my $cfg_delim_begin = '### Vyatta Accel PPPOE Begin ###';
my $cfg_delim_end = '### Vyatta Accel PPPOE End ###';

# GLOBAL
# PPPOE
# PPP OPTIONS
my %fields = (
	_global_dns1			=> undef,
	_global_dns2			=> undef,
	_global_wins1			=> undef,
	_global_wins2			=> undef,
	_global_ip_pool			=> [],
	_pppoe				=> undef,
	_pppoe_ac			=> undef,
	_pppoe_ifname_in_sid		=> undef,
	_pppoe_intfs			=> [],
	_pppoe_ip_pool			=> undef,
	_pppoe_mac_filter		=> undef,
	_pppoe_mppe			=> undef,
	_pppoe_pado_delay		=> undef,
	_pppoe_service			=> undef,
	_pppoe_tr101			=> undef,
	_pppoe_verbose			=> undef,
	_ppp_ccp			=> undef,
	_ppp_check_ip			=> undef,
	_ppp_ipv4			=> undef,
	_ppp_ipv6			=> undef,
	_ppp_ipv6_accept_peer_intf_id	=> undef,
	_ppp_ipv6_intf_id		=> undef,
	_ppp_ipv6_peer_intf_id		=> undef,
	_ppp_lcp_echo_failure		=> undef,
	_ppp_lcp_echo_interval		=> undef,
	_ppp_lcp_echo_timeout		=> undef,
	_ppp_min_mtu			=> undef,
	_ppp_ppp_mppe			=> undef,
	_ppp_mtu			=> undef,
	_ppp_sid_case			=> undef,
	_ppp_single_session		=> undef,
	_ppp_unit_cache			=> undef,
	_ppp_verbose			=> undef,
	_is_empty			=> 1,
);

#my %ppp-options = (
#);

sub new {
    my $that = shift;
    my $class = ref ($that) || $that;
    my $self = {
        %fields,
    };
    
    bless $self, $class;
    return $self;
}

sub setup_base {
	my ($self, $listNodes_func, $val_func, $vals_func, $exists_func) = @_;

	my $config = new Vyatta::Config;
	$config->setLevel('service accel-ppp');
	my @nodes = $config->$listNodes_func();
	if (scalar(@nodes) <= 0) {
		$self->{_is_empty} = 1;
		return 0;
	} else {
		$self->{_is_empty} = 0;
	}

	# Global options
	if (defined($config->$val_func('dns-servers server-1'))) {
		$self->{_global_dns1} = $config->$val_func('dns-servers server-1');
	}
	if (defined($config->$val_func('dns-servers server-2'))) {
		$self->{_global_dns2} = $config->$val_func('dns-servers server-2');
	}

	if (defined($config->$val_func('wins-servers server-1'))) {
		$self->{_global_wins1} = $config->$val_func('wins-servers server-1');
	}
	if (defined($config->$val_func('wins-servers server-2'))) {
		$self->{_global_wins2} = $config->$val_func('wins-servers server-2');
	}

	# PPPoE server
	if (defined($config->$vals_func('pppoe'))) {
		$self->{_pppoe}			= 1;
		$self->{_pppoe_ac}		= $config->$val_func('pppoe access-concentrator');
		$self->{_pppoe_ifname_in_sid}	= $config->$val_func('pppoe ifname-in-sid');
		$self->{_pppoe_ip_pool}		= $config->$val_func('pppoe ip-pool');
		$self->{_pppoe_mac_filter}	= $config->$val_func('pppoe mac-filter');
		$self->{_pppoe_mppe}		= $config->$val_func('pppoe mppe');
		$self->{_pppoe_pado_delay}	= $config->$val_func('pppoe pado-delay');
		$self->{_pppoe_service}		= $config->$val_func('pppoe service-name');
		$self->{_pppoe_tr101}		= $config->$val_func('pppoe tr101');
		$self->{_pppoe_verbose}		= $config->$val_func('pppoe verbose');

		my @intfs = $config->$listNodes_func('pppoe interface');
		foreach my $intf (@intfs) {
			$self->{_pppoe_intfs} = [ @{$self->{_pppoe_intfs}}, $intf];
		}
	}

	$self->{_ppp_ccp}			= $config->$val_func('ppp-options ccp');
	$self->{_ppp_check_ip}			= $config->$val_func('ppp-options check-ip');
	$self->{_ppp_ipv4}			= $config->$val_func('ppp-options ipv4');
	$self->{_ppp_ipv6}			= $config->$val_func('ppp-options ipv6');
	$self->{_ppp_ipv6_accept_peer_intf_id}	= $config->$val_func('ppp-options ipv6-accept-peer-intf-id');
	$self->{_ppp_ipv6_intf_id}		= $config->$val_func('ppp-options ipv6-intf-id');
	$self->{_ppp_ipv6_peer_intf_id}		= $config->$val_func('ppp-options ipv6-peer-intf-id');
	$self->{_ppp_lcp_echo_failure}		= $config->$val_func('ppp-options lcp-echo-failure');
	$self->{_ppp_lcp_echo_interval}		= $config->$val_func('ppp-options lcp-echo-interval');
	$self->{_ppp_lcp_echo_timeout}		= $config->$val_func('ppp-options lcp-echo-timeout');
	$self->{_ppp_min_mtu}			= $config->$val_func('ppp-options min-mtu');
	$self->{_ppp_ppp_mppe}			= $config->$val_func('ppp-options mppe');
	$self->{_ppp_mtu}			= $config->$val_func('ppp-options mtu');
	$self->{_ppp_sid_case}			= $config->$val_func('ppp-options sid-case');
	$self->{_ppp_single_session}		= $config->$val_func('ppp-options single-session');
	$self->{_ppp_unit_cache}		= $config->$val_func('ppp-options unit-cache');
	$self->{_ppp_verbose}			= $config->$val_func('ppp-options verbose');

	return 0;
}

sub setup {
    my ($self) = @_;
    
    $self->setup_base('listNodes', 'returnValue', 'returnValues', 'exists');
    return 0;
}

sub setupOrig {
    my ($self) = @_;
    
    $self->setup_base('listOrigNodes', 'returnOrigValue', 'returnOrigValue', 
                      'existsOrig');
    return 0;
}

sub listsDiff {
    my @a = @{$_[0]};
    my @b = @{$_[1]};
    return 1 if scalar @a != scalar @b;
    
    while (my $a = shift @a) {
        my $b = shift @b;
        return 1 if ($a ne $b);
    }
    return 0;
}

sub isDifferentFrom {
	my ($this, $that) = @_;

	return 1 if ($this->{_is_empty} ne $that->{_is_empty});
	return 1 if ($this->{_pppoe_ac} ne $that->{_pppoe_ac});
	return 1 if ($this->{_pppoe_service} ne $that->{_pppoe_service});
	return 1 if ($this->{_pppoe_mtu} ne $that->{_pppoe_mtu});
	return 1 if (listsDiff($this->{_pppoe_intfs}, $that->{_pppoe_intfs}));
	return 1 if ($this->{_global_dns1}, $that->{_global_dns1});
	return 1 if ($this->{_global_dns2}, $that->{_global_dns2});
	return 1 if ($this->{_global_wins1}, $that->{_global_wins1});
	return 1 if ($this->{_global_wins2}, $that->{_global_wins2});

	return 0;
}

sub needsRestart {
	 my ($this, $that) = @_;

	return 1 if ($this->{_is_empty} ne $that->{_is_empty});
	return 1 if ($this->{_pppoe_ac} ne $that->{_pppoe_ac});
	return 1 if ($this->{_pppoe_service} ne $that->{_pppoe_service});
	return 1 if ($this->{_pppoe_mtu} ne $that->{_pppoe_mtu});
	return 1 if (listsDiff($this->{_pppoe_intfs}, $that->{_pppoe_intfs}));
	return 1 if ($this->{_global_dns1}, $that->{_global_dns1});
	return 1 if ($this->{_global_dns2}, $that->{_global_dns2});
	return 1 if ($this->{_global_wins1}, $that->{_global_wins1});
	return 1 if ($this->{_global_wins2}, $that->{_global_wins2});

	return 0;
}

sub isEmpty {
    my ($self) = @_;
    return $self->{_is_empty};
}

sub get_ppp_opts {
	my ($self) = @_;
	my $loadmodules;
	my $config;
	my $finalconfig;

	# Global and hardcoded parameters
	$loadmodules .= "[modules]\n";
	$loadmodules .= "log_file\n";
	$loadmodules .= "auth_chap_md5\n";
	$loadmodules .= "ippool\n";
	$loadmodules .= "shaper\n";

	$config .= "[core]\n";
	$config .= "log-error=/var/log/accel-ppp/core.log\n";
	$config .= "thread-count=2\n\n";

	$config .= "[log]\n";
	$config .= "log-file=/var/log/accel-ppp/accel-ppp.log\n";
	$config .= "log-emerg=/var/log/accel-ppp/emerg.log\n";
	$config .= "log-fail-file=/var/log/accel-ppp/auth-fail.log\n";
	$config .= "level=5\n";
	$config .= "copy=1\n\n";

	$config .= "[cli]\n";
	$config .= "telnet=127.0.0.1:2000\n";
	$config .= "tcp=127.0.0.1:2001\n\n";


	$config .= "[dns]\n";	
	if (defined($self->{_global_dns1})) {
		$config .= "dns1=$self->{_global_dns1}\n";
	}
	if (defined($self->{_global_dns2})) {
		$config .= "dns2=$self->{_global_dns2}\n";
	}
	$config .= "\n";
	$config .= "[wins]\n";	
	if (defined($self->{_global_wins1})) {
		$config .= "wins1=$self->{_global_wins1}\n";
	}
	if (defined($self->{_global_wins2})) {
		$config .= "wins2=$self->{_global_wins2}\n";
	}
	$config .= "\n";


	# Generate PPPoE config
	if (defined($self->{_pppoe})) {
		return (undef, "Must define at least 1 interface")
			if scalar(@{$self->{_pppoe_intfs}}) < 1;

		$loadmodules .= "pppoe\n";
		$config .= "[pppoe]\n";

		# TODO: Get interface pado limit
		while (scalar(@{$self->{_pppoe_intfs}}) > 0) {
			my $intf = shift @{$self->{_pppoe_intfs}};
			$config .= "interface=$intf\n";
		}
		if (defined($self->{_pppoe_ac})) {
			$config .= "ac-name=$self->{_pppoe_ac}\n";
		}
		if (defined($self->{_pppoe_service})) {
			$config .= "service-name=$self->{_pppoe_service}\n";
		} else {
			$config .= "service-name=*\n";
		}
		if (defined($self->{_pppoe_pado_delay})) {
			$config .= "pado-delay=$self->{_pppoe_pado_delay}\n";
		}
		if (defined($self->{_pppoe_mac_filter})) {
			$config .= "mac-filter=$self->{_pppoe_mac_filter}\n";
		}
		if (defined($self->{_pppoe_ifname_in_sid})) {
			$config .= "ifname-in-sid=$self->{_pppoe_ifname_in_sid}\n";
		}
		if (defined($self->{_pppoe_pado_delay})) {
			$config .= "pado-delay=$self->{_pppoe_pado_delay}\n";
		}
		if (defined($self->{_pppoe_verbose})) {
			$config .= "verbose=$self->{_pppoe_verbose}\n";
		} else {
			$config .= "verbose=1\n";
		}
		if (defined($self->{_pppoe_tr101})) {
			$config .= "tr101=$self->{_pppoe_tr101}\n";
		}
		if (defined($self->{_pppoe_padi_limit})) {
			$config .= "padi-limit=$self->{_pppoe_padi_limit}\n";
		}
		if (defined($self->{_pppoe_mppe})) {
			$config .= "mppe=$self->{_pppoe_mppe}\n";
		}
		if (defined($self->{_ip_pool})) {
			$config .= "ip-pool=$self->{_pppoe_ip_pool}\n";
		}
		$config .= "\n";
	}


	# Generate PPP options
	$config .= "[ppp]\n";
	if (defined($self->{_ppp_ccp})) {
		$config .= "ccp=$self->{_ppp_ccp}\n";
	}
	if (defined($self->{_ppp_check_ip})) {
		$config .= "check-ip=$self->{_ppp_check_ip}\n";
	}
	if (defined($self->{_ppp_ipv4})) {
		$config .= "ipv4=$self->{_ppp_ipv4}\n";
	} else {
		$config .= "ipv4=require\n";
	}
	if (defined($self->{_ppp_ipv6})) {
		$config .= "ipv6=$self->{_ppp_ipv6}\n";
	} else {
		$config .= "ipv6=deny\n";
	}
	if (defined($self->{_ppp_ipv6_accept_peer_intf_id})) {
		$config .= "ipv6-accept-peer-intf-id=$self->{_ppp_ipv6_accept_peer_intf_id}\n";
	}
	if (defined($self->{_ppp_ipv6_intf_id})) {
		$config .= "ipv6-intf-id=$self->{_ppp_ipv6_intf_id}\n";
	}
	if (defined($self->{_ppp_ipv6_peer_intf_id})) {
		$config .= "ipv6-peer-intf-id=$self->{_ppp_ipv6_peer_intf_id}\n";
	}
	if (defined($self->{_ppp_lcp_echo_failure})) {
		$config .= "lcp-echo-failure=$self->{_ppp_lcp_echo_failure}\n";
	}
	if (defined($self->{_ppp_lcp_echo_interval})) {
		$config .= "lcp-echo-interval=$self->{_ppp_lcp_echo_interval}\n";
	} else {
		$config .= "lcp-echo-interval=30\n";
	}
	if (defined($self->{_ppp_lcp_echo_timeout})) {
		$config .= "lcp-echo-timeout=$self->{_ppp_lcp_echo_timeout}\n";
	} else {
		$config .= "lcp-echo-timeout=120\n";
	}
	if (defined($self->{_ppp_min_mtu})) {
		$config .= "min-mtu=$self->{_ppp_min_mtu}\n";
	} else {
		$config .= "min-mtu=1280\n";
	}
	if (defined($self->{_ppp_mppe})) {
		$config .= "mppe=$self->{_ppp_ppp_mppe}\n";
	} else {
		$config .= "mppe=deny\n";
	}
	if (defined($self->{_ppp_mtu})) {
		$config .= "mtu=$self->{_ppp_mtu}\n";
		$config .= "mru=$self->{_ppp_mtu}\n";
	} else {
		$config .= "mtu=1450\n";
		$config .= "mru=1450\n";
	}
	if (defined($self->{_ppp_sid_case})) {
		$config .= "sid-case=$self->{_ppp_sid_case}\n";
	}
	if (defined($self->{_ppp_single_session})) {
		$config .= "single-session=$self->{_ppp_single_session}\n";
	}
	if (defined($self->{_ppp_unit_cache})) {
		$config .= "unit-cache=$self->{_ppp_unit_cache}\n";
	}
	if (defined($self->{_ppp_verbose})) {
		$config .= "verbose=$self->{_ppp_verbose}\n";
	} else {
		$config .= "verbose=1\n";
	}
	$config .= "\n";

	$finalconfig  = "$cfg_delim_begin\n";
	$finalconfig .= $loadmodules . "\n";
	$finalconfig .= $config;
	$finalconfig .= "\n$cfg_delim_end\n";

	#return (undef, $finalconfig)
	#	if 2 > 1;

	return ($finalconfig, undef);
}

sub removeCfg {
    my ($self, $file) = @_;

    system("sed -i '/$cfg_delim_begin/,/$cfg_delim_end/d' $file");
    if ($? >> 8) {
        print STDERR 
            "accel-ppp configuration error: Cannot remove old config from $file.\n";
        
        return 0;
    }
    return 1;
}

sub writeCfg {
    my ($self, $file, $cfg, $append, $delim) = @_;

    my $op = ($append) ? '>>' : '>';
    my $WR = undef;
    if (!open($WR, $op, "$file")) {
        print STDERR 
            "accel-ppp configuration error: Cannot write config to $file.\n";
        return 0;
    }
    if ($delim) {
        $cfg = "$cfg_delim_begin\n" . $cfg . "\n$cfg_delim_end\n";
    }
    print ${WR} "$cfg";
    close $WR;
    return 1;
}

sub print_str {
    my ($self) = @_;

    my $str = 'accel-ppp';
#    $str .= "\n  intfs " . (join ",", @{$self->{_intfs}});
#    $str .= "\n  cip_start " . $self->{_client_ip_start};
#    $str .= "\n  cip_stop " . $self->{_client_ip_stop};
#    $str .= "\n  auth_mode " . $self->{_auth_mode};
#    $str .= "\n  auth_local " . (join ",", @{$self->{_auth_local}});
#    $str .= "\n  auth_radius " . (join ",", @{$self->{_auth_radius}});
#    $str .= "\n  auth_radius_s " . (join ",", @{$self->{_auth_radius_keys}});
#    $str .= "\n  dns " . (join ",", @{$self->{_dns}});
#    $str .= "\n  wins " . (join ",", @{$self->{_wins}});
#    $str .= "\n  empty " . $self->{_is_empty};
#    $str .= "\n";

  return $str;
}

1;
