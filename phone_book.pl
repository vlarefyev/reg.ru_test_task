use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use DBI;

my $host      = '*****';
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

# Проверяем существование таблиц и создаём их

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
  primary key (id)
);
END_SQL
$dbh->do($sql_create_table_contacts);

}

if ( not(grep( /^phone_numbers$/, @tables )) ) {

my $sql_create_table_phone_numbers = <<'    END_SQL';
    CREATE TABLE phone_numbers (
    id            INTEGER NOT NULL AUTO_INCREMENT,
    contact_id    INTEGER NOT NULL,
    phone         VARCHAR(100) UNIQUE NOT NULL,
    type_phone    VARCHAR(100) NOT NULL,
    primary key (id)
    );
    END_SQL
$dbh->do($sql_create_table_phone_numbers);

}

# Выводим меню

(my $hello_message = qq{
    Замечательная телефонная книжка!
}) =~ s/^ {4}//mg;

print $hello_message;

while ( 42 ) {
    
    (my $start_message = qq{
        Выбери дальнейшее действие: 

        1) Показать все контакты;
        2) Добавить контакт;
        3) Удалить контакт;
        4) Изменить контакт.
    }) =~ s/^ {4}//mg;

    print $start_message;

    my $choice = <STDIN>;
    chomp $choice;

    if ( looks_like_number($choice) ) {
        if ( $choice == 1 ) {
            print "Ты выбрал 1 => Показать все контакты\n";
            last;
        } elsif ( $choice == 2 ) {
            print "Ты выбрал 2 => Добавить контакт\n";

            my $fname;
            my $lname;
            my $patronymic_name;
            my $phone;
            my $phone_type;

            while ( 42 ) {

                print "Введи имя ";
                $fname = <STDIN>;
                chomp $fname;
                $fname = trim($fname);

                print "Введи фамиллию ";
                $lname = <STDIN>;
                chomp $lname;
                $lname = trim($lname);

                print "Введи отчество (при наличии) ";
                $patronymic_name = <STDIN>;
                chomp $patronymic_name;
                $patronymic_name = trim($patronymic_name);

                while ( 42 ) {
                    print "Введи телефон в формате 8-999-999-99-99 ";
                
                    my $phone_unconfirmed = <STDIN>;
                    chomp $phone_unconfirmed;
                    $phone_unconfirmed = trim($phone_unconfirmed);

                    if ( $phone_unconfirmed =~ m/^[0-9]{1,3}-[0-9]{3}-[0-9]{3}-[0-9]{2}-[0-9]{2}$/ ) {
                        $phone = $phone_unconfirmed;
                        last;
                    } else {
                        next;
                    }};

                while ( 42 ) {

                    print "Укажи тип телефона m/s (мобильный/стационарный) ";
                    my $phone_type_unconfirmed = <STDIN>;
                    chomp $phone_type_unconfirmed;
                    $phone_type_unconfirmed = trim($phone_type_unconfirmed);

                    if ( $phone_type_unconfirmed =~ m/^[ms]{1}$/) {
                        $phone_type = $phone_type_unconfirmed;
                        last;
                    } else {
                        next;
                }};

                (my $final_message = qq{Отлично, проверь, всё ли правильно записано:

                    Имя: $fname
                    Фамиллия: $lname
                    Отчество: $patronymic_name
                    Телефон: $phone
                    Тип телефона: $phone_type

                    Всё верно?

                    1) Записать контакт;
                    2) Ввести заново;
                    3) Вернуться в основное меню.
                }) =~ s/^ {2}//mg;
                print $final_message;

                my $choice = <STDIN>;
                chomp $choice;
                
                if ( looks_like_number($choice) ) {

                    if ( $choice == 1 ) {
                            my $add_contact = <<"                                END_SQL";
                                    INSERT contacts (fname, lname, patronymic)
                                    VALUES ('$fname', '$lname', '$patronymic_name');
                                END_SQL
                            $dbh->do($add_contact);

                            my $add_phone = <<"                                END_SQL";
                                    INSERT phone_numbers (contact_id, phone, type_phone)
                                    VALUES (LAST_INSERT_ID(), '$phone', '$phone_type'); 
                                END_SQL
                            $dbh->do($add_phone);

                        print "Контакт записан";
                        last;
                    } elsif ( $choice == 2 ) {
                        next;
                    } else {
                        last;
                    }
                } 
            };
        } elsif ( $choice == 3 ) {
            print "Ты выбрал 3 => Удалить контакт\n";
            last;
        } elsif ( $choice == 4 ) {
            print "Ты выбрал 4 => Изменить контакт\n";
            last;
        } else {
            print "Такого варианта нет. Попробуй ещё раз\n"
        }
        } else {
            print "Введённое значение не является числом. Попробуй ещё раз\n"
        }

}