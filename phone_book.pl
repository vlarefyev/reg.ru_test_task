use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use DBI;
use utf8;

binmode STDOUT, ":utf8";

my $host      = "*****";
my $port      = "*****";
my $user      = "*****";
my $database  = "*****";
my $password  = "*****";

# Устанавливаем соединение с БД
my $dsn      = "DBI:mysql:database=$database;host=$host;port=$port";
my $dbh = DBI->connect ($dsn, $user, $password, {mysql_enable_utf8 => 1}) or die "Не удалось установить соединение с базой данных: " . DBI->errstr();

# Вспомогательные функции

sub  trim { 
    my $text = shift; 
    $text =~ s/^\s+|\s+$//g; 
    return $text 
}

sub send_request_to_database {

    my $request = shift;
    $dbh->do($request);

}

sub get_response_user {

    my $response = <STDIN>;
    chomp $response;
    $response = trim("$response");
    return $response

}

sub check_valid_phone {
    my $phone = shift;

    if ( $phone =~ m/^[0-9]{1,3}(-[0-9]{3}){2}(-[0-9]{2}){2}$/ ) {
        return 1;
    } else {
        return 0;
    }
}

sub check_valid_name {
    
    my $name = shift;

    utf8::decode($name);

    if ( $name =~ m/^[a-zA-Zа-яА-Я-]{2,20}$/ ) {
        return $name
    } else {
        return 0
    }
}

sub create_table {

    my @tables;
    my $sql_show_tables = $dbh->prepare("show tables;");
    $sql_show_tables->execute();

    while (my $table = $sql_show_tables->fetchrow_array() ) {

    push @tables, $table;

    };

    if ( not(grep( /^contacts$/, @tables )) ) {
        
    (my $sql_create_table_contacts = qq{
    CREATE TABLE contacts (
    id            INTEGER NOT NULL AUTO_INCREMENT,
    fname         VARCHAR(100) NOT NULL,
    lname         VARCHAR(100) NOT NULL,
    patronymic    VARCHAR(100),
    phone         VARCHAR(100) UNIQUE NOT NULL,
    type_phone    VARCHAR(100) NOT NULL,
    primary key (id)
    )}) =~ s/^ +//mg;

    send_request_to_database($sql_create_table_contacts)

    }

}

sub contact_search {

    my $search_parameter = shift;

    if ( check_valid_phone($search_parameter) ) {

        my $sql_check_phone = $dbh->prepare("SELECT id, fname, lname, patronymic, phone, type_phone FROM contacts WHERE phone='$search_parameter'");
        $sql_check_phone->execute();
        my @contact = $sql_check_phone->fetchrow_array();
        return @contact     

    } elsif ( looks_like_number($search_parameter) ) {
        
        my $sql_check_id = $dbh->prepare("SELECT id, fname, lname, patronymic, phone, type_phone FROM contacts WHERE id='$search_parameter'");
        $sql_check_id->execute();
        my @contact = $sql_check_id->fetchrow_array();
        return @contact  
    }
}

sub enter_phone {

    print "Введи телефон в формате 8-999-999-99-99\n";

    my $phone_unconfirmed = &get_response_user;

    if ( check_valid_phone($phone_unconfirmed) ) {
        return $phone_unconfirmed;
    } else {
        print "Номер введён не верно\n";
        &enter_phone
    }
}

sub enter_phone_type {

    (my $message = qq{
        Выбери тип телефона: 
        1) Мобильный;
        2) Стационарный.\n\n}) =~ s/^ +//mg;

    print $message;

    my $phone_type_unconfirmed = &get_response_user;

    if ( $phone_type_unconfirmed =~ m/^[12]{1}$/) {
        if ( $phone_type_unconfirmed == 1 ) {
            return "m";
        } else {
            return "s";
        }
    } else {
        print "Такого варианта нет. Попробуй ещё раз";
        &enter_phone_type;
    }
}  

sub enter_name {

    my $name_type_received  = $_[0];
    my $name_text;
    my $alt_name_text;
    
    if ( $name_type_received  eq "fname" ){
        $alt_name_text = $name_text = "имя"    
    } elsif ( $name_type_received  eq "lname" ) {
        $alt_name_text = "фамилия";
        $name_text = "фамилию"
    } elsif ( $name_type_received  eq "patronymic" ) {
        $alt_name_text = $name_text = "отчество"
    } else {
        print "Ошибка! Несушествующий тип имени $name_type_received";
        exit;
    }

    print "Введи $name_text\n";
    my $name_to_check = &get_response_user;

    my $name_test = check_valid_name("$name_to_check");

    if ( not ($name_test) ) {
        (my $error_message = qq{
        Поле $alt_name_text введено не корректно. 
        Повтори попытку.
        
        Требования к написанию:

        От 2 до 20 символов;
        Допускается специальный символ "-"\n}) =~ s/^ +//mg;
        print $error_message;
        &enter_name
    } else {
        return $name_test
    }

}

# Основные функции

sub print_all_contact {
            
    my @all_contact;
    
    my $sql_all_contact = $dbh->prepare("SELECT id, fname, lname, patronymic, phone, type_phone FROM contacts");
    $sql_all_contact->execute();

    while (my @table = $sql_all_contact->fetchrow_array() ) {

    my $id          =     $table[0];
    my $fname       =     $table[1];
    my $lname       =     $table[2];
    my $patronymic  =     $table[3];
    my $phone       =     $table[4];
    my $phone_type  =     $table[5];

    my $phone_type_text;

    if ( $phone_type eq "m" ) {
        $phone_type_text = "Мобильный"
    } elsif ( $phone_type eq "s" ) {
        $phone_type_text = "Стационарный"
    } else {
        print "Ошибка, из базы вернулось не корректное значение поля $phone_type"
    }

    print "Контакт № $id   $lname  $fname  $patronymic ----> $phone $phone_type_text\n";
    
    };

    &start_menu
}

sub add_contact {

    my $fname = enter_name("fname");
    my $lname = enter_name("lname");
    my $patronymic_name = enter_name("patronymic");  
    my $phone = &enter_phone;
    my $phone_type = &enter_phone_type;    

    (my $final_message = qq{
        Отлично, проверь, всё ли правильно записано:

        Имя: $fname
        Фамиллия: $lname
        Отчество: $patronymic_name
        Телефон: $phone
        Тип телефона: $phone_type

        Всё верно?

        1) Записать контакт;
        2) Ввести заново;
        3) Вернуться в основное меню.
        }) =~ s/^ +//mg;
    print $final_message;

    my $choice = &get_response_user;

    if ( looks_like_number($choice) ) {

        if ( $choice == 1 ) {
            my $add_contact = qq{
                INSERT contacts (fname, lname, patronymic, phone, type_phone)
                VALUES ('$fname', '$lname', '$patronymic_name', '$phone', '$phone_type')};        
                send_request_to_database($add_contact);
                print "\nКонтакт записан\n";
                &start_menu;
        } elsif ( $choice == 2 ) {
            &add_contact;       
        } else {
            &start_menu;
        }
    } 

}

sub del_contact {

    print "Введи номер, который хочешь удалить в формате 8-999-999-99-99 либо ID контакта\n";
    
    my $del_cuntact_data = &get_response_user;

        my ($id_to_del, $fmane_to_del, $lname_to_del, $patronymic_to_del, $phone_to_del, $phone_type_to_del) = contact_search($del_cuntact_data);

        if ( $phone_to_del ) {
            (my $message = qq{
            Найден контакт: $id_to_del $lname_to_del $fmane_to_del $patronymic_to_del телефон $phone_to_del  $phone_type_to_del
            Чтобы удалить контакт введи yes. 
            Введи любое другое значение для отмены и возврата в меню.\n}) =~ s/^ +//mg;

            print $message;
            
            my $choice = &get_response_user;

            if ( $choice eq ("yes") ) {
                my $del_phone = "DELETE FROM contacts where phone='$phone_to_del'";
                send_request_to_database($del_phone);
                print "Контакт удалён!";
                &start_menu
            } else {
                &start_menu
            }
        } else {
            print "Номер не найден!";
            &start_menu
        }
}

sub update_contact {

    print "Введи номер контакта, которого хочешь изменить в формате 8-999-999-99-99 либо ID контакта\n";

    my $uptate_cuntact_data = &get_response_user;

        my ($id_to_up, $fmane_to_up, $lname_to_up, $patronymic_to_up, $phone_to_up, $phone_type_to_up) = contact_search($uptate_cuntact_data);

        if ( $phone_to_up ) {
            (my $message = qq{
            Найден контакт: $id_to_up $lname_to_up $fmane_to_up $patronymic_to_up телефон $phone_to_up  $phone_type_to_up
            Выбери, что нужно изменить:

            1) Имя;
            2) Фамилию;
            3) Отчество;
            4) Номер телефона;
            5) Тип телефона; 
            
            0) Вернуться в главное меню\n}) =~ s/^ +//mg;

            print $message;

            my $choice = &get_response_user;

            if ( $choice == 0 ) {
                &start_menu;
            }

            sub get_variable_to_up {

                my $choice = shift;

                my $data_update;
                my @variables = ("fname", "lname", "patronymic", "phone", "type_phone");
                my $variable = $variables[($choice - 1)];

                if ( $choice =~ m/[1-5]{1}/ ) {              
                   
                    if ( $choice =~ m/[1-3]{1}/ ) {

                        $data_update = enter_name($variable)

                    } elsif ( $choice == 4 ) {

                        $data_update = enter_phone()

                    } elsif ( $choice == 5 ) {

                        $data_update = enter_phone_type()

                    } else {

                        print "Такого варианта нет. Попробуй ещё раз";
                        &phone_to_up;
                    
                    }
                };

                return ($data_update, $variable)
            }

            my ($variable_to_up, $variable_type) = &get_variable_to_up( $choice );

            my $sql_request_update = "UPDATE contacts SET $variable_type = '$variable_to_up' WHERE id='$id_to_up'";
            send_request_to_database($sql_request_update);
            print "Контакт изменён!\n";      
            &start_menu;
        } else {
            print "\nНомер не найден!\n";
            &start_menu;
        };

}

sub start_menu {

    (my $start_message = qq{
        Выбери дальнейшее действие: 

        1) Показать все контакты;
        2) Добавить контакт;
        3) Удалить контакт;
        4) Изменить контакт;
        
        0) Выйти из программы.\n\n}) =~ s/^ +//mg;

    print $start_message;

    my $choice = <STDIN>;
    chomp $choice;

    if ( looks_like_number($choice) ) {
        if ( $choice == 1 ) {
            &print_all_contact;
        } elsif ( $choice == 2 ) {
            &add_contact;
        } elsif ( $choice == 3 ) {
            &del_contact;
        } elsif ( $choice == 4 ) {
            &update_contact;
        } elsif ( $choice == 0 ) {
            exit
        } else {
            print "Такого варианта нет. Попробуй ещё раз\n";
            &start_menu
        };
        } else {
            print "Введённое значение не является числом. Попробуй ещё раз\n";
            &start_menu
        }
}

# Старт программы

(my $hello_message = qq{
    Замечательная телефонная книжка!
}) =~ s/^ +//mg;

print $hello_message;

&create_table;
&start_menu;