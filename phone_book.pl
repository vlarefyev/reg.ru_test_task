use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use DBI;

my $host      = "*****";
my $port      = "*****";
my $user     = "*****";
my $password = "*****";

# Устанавливаем соединение с БД
my $dsn      = "DBI:mysql:database=task_regru;host=$host;port=$port";
my $dbh = DBI->connect ($dsn, $user, $password) or die "Не удалось установить соединение с базой данных: " . DBI->errstr();

# Вспомогательные функции

sub  trim { 
    my $text = shift; 
    $text =~ s/^\s+|\s+$//g; 
    return $text 
};

sub get_response_user {

    my $response = <STDIN>;
    chomp $response;
    $response = trim("$response");
    return $response

};

sub check_valid_phone {
    my $phone = shift;

    if ( $phone =~ m/^[0-9]{1,3}-[0-9]{3}-[0-9]{3}-[0-9]{2}-[0-9]{2}$/ ) {
        return 1;
    } else {
        return 0;
    }
};

############################ Поменять название
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
};

sub send_request_to_database {

    my $request = shift;
    $dbh->do($request);

};

# Основные функции

sub print_all_contact {
            
    my @all_contact;
    
    my $sql_all_contact = $dbh->prepare("SELECT id, fname, lname, patronymic, phone FROM contacts");
    $sql_all_contact->execute();

    while (my @table = $sql_all_contact->fetchrow_array() ) {

    my $id          =     $table[0];
    my $fname       =     $table[1];
    my $lname       =     $table[2];
    my $patronymic  =     $table[3];
    my $phone       =     $table[4];

    print "Контакт № $id   $lname  $fname  $patronymic ----> $phone\n";
    
    };

};

sub add_contact {

    sub enter_phone {

        print "Введи телефон в формате 8-999-999-99-99\n";

        my $phone_unconfirmed = &get_response_user;

        if ( check_valid_phone($phone_unconfirmed) ) {
            return $phone_unconfirmed;
        } else {
            print "Номер введён не верно\n";
            &enter_phone
        }};


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
        }};    
    
    print "Введи имя\n";
    my $fname = &get_response_user;

    print "Введи фамиллию\n";
    my $lname = &get_response_user;

    print "Введи отчество (при наличии)\n";
    my $patronymic_name = &get_response_user;   

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
                print "Контакт записан";
        } elsif ( $choice == 2 ) {
            &add_contact;       
        } else {
            print "Тут основная функция"
        }
    } 

};

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
                print "Контакт удалён!"
            }
        } else {
            print "Номер не найден!";
            ############### Тут возврат в основную функцию.
        }
};

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

            if ( $choice =~ m/[1-5]{1}/ ) {
                
                my @variables = ("fname", "lname", "patronymic", "phone", "type_phone");
                my $variable = $variables[($choice - 1)];

                print "Введи новое значение\n";

                my $new_value = &get_response_user;

                my $sql_request_update = "UPDATE contacts SET $variable = '$new_value' WHERE id='$id_to_up'";
                send_request_to_database($sql_request_update);
                print "Контакт изменён!\n"          

            } elsif ( $choice == 0 ) {
                print "Выход из функции"
            } else {
                print "что-то введено не так"
            }
};

};
# Проверяем существование таблицы и создаём её

my @tables;
my $sql_show_tables = $dbh->prepare("show tables;");
$sql_show_tables->execute();

while (my $table = $sql_show_tables->fetchrow_array() ) {

push @tables, $table;

};

if ( not(grep( /^contacts$/, @tables )) ) {
    
my $sql_create_table_contacts = <<'END_SQL';
CREATE TABLE contacts (
  id            INTEGER NOT NULL AUTO_INCREMENT,
  fname         VARCHAR(100) NOT NULL,
  lname         VARCHAR(100) NOT NULL,
  patronymic    VARCHAR(100),
  phone         VARCHAR(100) UNIQUE NOT NULL,
  type_phone    VARCHAR(100) NOT NULL,
  primary key (id)
);
END_SQL
$dbh->do($sql_create_table_contacts);

}

# Выводим меню

(my $hello_message = qq{
    Замечательная телефонная книжка!
}) =~ s/^ +//mg;

print $hello_message;

while ( 42 ) {
    
    (my $start_message = qq{
        Выбери дальнейшее действие: 

        1) Показать все контакты;
        2) Добавить контакт;
        3) Удалить контакт;
        4) Изменить контакт.\n\n}) =~ s/^ {8}//mg;

    print $start_message;

    my $choice = <STDIN>;
    chomp $choice;

    if ( looks_like_number($choice) ) {
        if ( $choice == 1 ) {
            &print_all_contact;
            next;
        } elsif ( $choice == 2 ) {
            &add_contact;
        } elsif ( $choice == 3 ) {
            &del_contact;
        } elsif ( $choice == 4 ) {
            &update_contact;
        } else {
            print "Такого варианта нет. Попробуй ещё раз\n"
        };
        } else {
            print "Введённое значение не является числом. Попробуй ещё раз\n"
        }
        
}
