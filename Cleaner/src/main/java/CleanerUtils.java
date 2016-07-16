import javax.mail.internet.MimeMessage;
import javax.mail.*;
import java.util.regex.*;

public class CleanerUtils
{
  //Implements a Regex expression that checks the validity of emails
  public static boolean isValidEmailAddress(String emailAddress)
  {
    Pattern validEmail = Pattern.compile("^[_A-Za-z0-9-\\+]+(\\.[_A-Za-z0-9-']+)*@"
    + "[A-Za-z0-9-]+(\\.[A-Za-z0-9]+)*(\\.[A-Za-z]{2,})$");
    Matcher m = validEmail.matcher(emailAddress);
    return m.matches();
  }

  //Replaces the .. or '.' found in a large number of invalid email addresses with .
  public static String replaceDotDot(String emailAddress)
  {
    emailAddress = emailAddress.replace(".'.'",".");
    emailAddress = emailAddress.replace("..",".");
    return emailAddress;
  }

  //Checks to see if emailAddress is a blacklisted "To" address
  public static boolean NotInToBlacklist(String emailAddress)
  {
    String toBlacklist[] = {"undisclosed.recipients@mailman.enron.com","undisclosed-recipients@enron.com","announcement","pete.davis@enron.com","notification",
                            "recipients@enron.com","team","postmaster"};

    if(!emailAddress.contains("@enron.com"))
    {
      return false;
    }

    for(int i = 0; i < toBlacklist.length; i++)
    {
      if(emailAddress.contains(toBlacklist[i]))
      {
        return false;
      }
    }
    return true;
  }

  //Checks to see if emailAddress is a blacklisted "From" address
  public static boolean NotInFromBlacklist(String emailAddress)
  {
    //pete davis known to act as proxy for broadcasts : http://www.casos.cs.cmu.edu/publications/papers/diesner_2005_communicationnetworks.pdf
    String fromBlacklist[] = {"no.address@enron.com","mailman","newsletter","unsubscribe","amazon.com","promotions","survey","reply","deals","announcement","pete.davis@enron.com",
                              "outlook.team@enron.com","team","postmaster"};

    if(!emailAddress.contains("@enron.com"))
    {
      return false;
    }

    for(int i = 0; i < fromBlacklist.length; i++)
    {
      if(emailAddress.contains(fromBlacklist[i]))
      {
        return false;
      }
    }
    return true;
  }

  //Remove spam by scannning Subject for specific terms, scannning Body for specific terms, and checking if From is on a blacklist
  public static boolean isSpam(String Subject, String Body, Address From[])
  {
    if(Subject.contains("Win ") || Subject.contains("Viagra") ||
    Subject.contains("XXX ") || Subject.contains("NSFW") ||
    (Subject.contains("%") && Subject.contains("Save")) ||
    Subject.contains("Free") || Subject.contains("Download") ||
    Subject.contains("porn") || Subject.contains("SEX") || Subject.contains("$"))
    {
      return true;
    }

    else
    {
      return false;
    }
  }
}
