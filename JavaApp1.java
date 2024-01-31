import java.sql.*;
import java.util.Scanner;

public class JavaApp1 {
    private static final Scanner S = new Scanner(System.in);

    private static Connection c = null;

    public static void main(String[] args) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            c = DriverManager.getConnection(); // ToDo : Specify Parameters !

            String choice = "";

            do {
                System.out.println("-- MAIN MENU --");
                System.out.println("1 - Browse ResultSet");
                System.out.println("2 - Invoke Procedure");
                System.out.println("Q - Quit");
                System.out.print("Pick : ");

                choice = S.next().toUpperCase();

                switch (choice) {
                    case "1" : {
                        browseResultSet();
                        break;
                    }
                    case "2" : {
                        invokeProcedure();
                        break;
                    }
                }
            } while (!choice.equals("Q"));

            c.close();

            System.out.println("Bye Bye :)");
        }
        catch (Exception e) {
            System.err.println(e.getMessage());
        }
    }

    private static void browseResultSet() throws Exception {
        Statement s = c.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);

        ResultSet rs = s.executeQuery(); // ToDo : Specify Query !

        // ToDo : Check ResultSet Contains Rows !
            // ToDo : Display ResultSet Rows !
    }

    private static void invokeProcedure() throws Exception {
        // ToDo : Receive Course Code & Course Date !
        // ToDo : Specify CallableStatement !
    }
}
