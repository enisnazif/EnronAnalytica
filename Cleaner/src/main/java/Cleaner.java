/*This program operates upon a folder of the enron text files, and cleans it
according to a set of rules by removing files from the folder */

/*The program then produces a CSV file of the form:

(Date, sender, recipient, isCc)
2342342235, p.allen@enron.com, e.nazif@warwick.ac.uk, 0
4242342333, k.lay@enron.com, p.allen@enron.com, 1
etc...

containing information about every single interaction*/

import java.util.*;
import javax.mail.*;
import java.nio.file.*;
import java.io.*;
import java.nio.*;
import javax.mail.internet.MimeMessage;

public class Cleaner
{
  public static void main(String args[])
  {
    Path dir = Paths.get(args[0]);
    TreeSet<EmailTuple> UniqueTuples = new TreeSet<EmailTuple>();
    TreeSet<String> UniqueIndividuals = new TreeSet<String>();
    TreeSet<CommunicationPair> UniquePairs = new TreeSet<CommunicationPair>();
    ArrayList<CommunicationPair> UniquePairsList = new ArrayList<CommunicationPair>();
    HashMap<String, Integer> IndividualMap = new HashMap<String, Integer>();

    Address From[];
    Address To[];
    Address Cc[];
    Address Bcc[];

    int duplicates = 0;
    int nulls = 0;
    int spam = 0;
    int invalidTime = 0;

    ArrayList<String> FromList;
    ArrayList<String> ToList;
    ArrayList<String> CcList;

    EmailTuple EmailT;

    FileWriter interactions = null;
    FileWriter individuals = null;
    FileWriter messageDates = null;

    //Open interactions file for writing
    try
	  {
	    interactions = new FileWriter(args[1]);
      interactions.flush();
    }
    catch(IOException e)
    {}

    //Open individuals file for writing
    try
    {
      individuals = new FileWriter(args[2]);
      individuals.flush();
    }
    catch(IOException e)
    {}

    try
    {
      messageDates = new FileWriter(args[3]);
      messageDates.flush();
    }
    catch(IOException e)
    {}

    try
    {
      DirectoryStream<Path> stream = Files.newDirectoryStream(dir);
      for (Path file : stream)
      {
        File mailFiles = file.toFile();

        try
        {
          FileInputStream fis = new FileInputStream(mailFiles);
          MimeMessage email = new MimeMessage(null, fis);

          //Parsing email data
          String MessageID = email.getMessageID();
          String Filename = mailFiles.getName();
          Date Date = email.getSentDate();
          String Subject = email.getSubject();
          From = email.getFrom();
          To = email.getRecipients(Message.RecipientType.TO);
          Cc = email.getRecipients(Message.RecipientType.CC);
          Bcc = email.getRecipients(Message.RecipientType.BCC);
          String Body = email.getContent().toString();

          FromList = new ArrayList<String>();
          ToList = new ArrayList<String>();
          CcList = new ArrayList<String>();

          //Close the FileInputStream when done
          fis.close();

          //System.out.println(Date.toString());
          //if the sent year is before 1998 (i.e earliest legit timestamp), remove the email
          if(Date != null)
          {
            if(Date.getYear() < 97 | Date.getYear() > 103)
            {
              try
              {
                Files.delete(file);
                System.out.println(Filename + " deleted for invalid timestamp");
                invalidTime++;
                continue;
              }
              catch (NoSuchFileException x)
              {}
            }
          }
          else
          {
            try
            {
              Files.delete(file);
              System.out.println(Filename + " deleted for null date");
              nulls++;
              continue;
            }
            catch (NoSuchFileException x)
            {}
          }

          if (From != null)
          {
            for (int i = 0; i < From.length; i++)
            {
              String fromString = CleanerUtils.replaceDotDot(From[i].toString());
              if(CleanerUtils.isValidEmailAddress(fromString) && CleanerUtils.NotInFromBlacklist(fromString))
              {
                FromList.add(fromString);
              }
            }
          }

          if (To != null)
          {
            for(int i = 0; i < To.length; i++)
            {
              String toString = CleanerUtils.replaceDotDot(To[i].toString());
              if(CleanerUtils.isValidEmailAddress(toString) && CleanerUtils.NotInToBlacklist(toString))
              {
                ToList.add(toString);
              }
            }
          }

          if (Cc != null)
          {
            for(int i = 0; i < Cc.length; i++)
            {
              String CcString = CleanerUtils.replaceDotDot(Cc[i].toString());
              if(CleanerUtils.isValidEmailAddress(CcString))
              {
                CcList.add(CcString);
              }
            }
          }

          //if the email has no from field, remove the email
          if(FromList.size() == 0)
          {
            try
            {
                Files.delete(file);
                System.out.println(Filename + " deleted for null from");
                nulls++;
                continue;
            }
            catch (NoSuchFileException x)
            {}
          }

          //if the email has no to field, remove the email
          if(ToList.size() == 0)
          {
            try
            {
                Files.delete(file);
                System.out.println(Filename + " deleted for null to");
                nulls++;
                continue;
            }
            catch (NoSuchFileException x)
            {}
          }

          //Searching for particular terms in the Subject which suggest spam
          if(CleanerUtils.isSpam(Subject, Body, From))
          {
            try
            {
                Files.delete(file);
                System.out.println(Filename + " deleted for being spam");
                spam++;
                continue;
            }
            catch (NoSuchFileException x)
            {}
          }

          //remove duplicate emails
          EmailT = new EmailTuple(Subject, Date, To, From, Cc, Body);
          if(!UniqueTuples.add(EmailT))
          {
            System.out.println(Filename + " deleted for being a duplicate");
            try
            {
                Files.delete(file);
                duplicates++;
                continue;
            }
            catch (NoSuchFileException x)
            {}
          }

          try
          {
              for(int i = 0; i < ToList.size(); i++)
              {
                  CommunicationPair A = new CommunicationPair(ToList.get(i), FromList.get(0), 2);
                  if(UniquePairs.add(A))
                  {
                    UniquePairsList.add(A);
                  }
                  else
                  {
                    int index = UniquePairsList.indexOf(UniquePairs.floor(A));
                    UniquePairsList.get(index).setWeight(UniquePairsList.get(index).getWeight() + 1);
                  }
              }

              interactions.flush();

              for(int i = 0; i < CcList.size(); i++)
              {
                CommunicationPair B = new CommunicationPair(CcList.get(i), FromList.get(0), 1);
                if(UniquePairs.add(B))
                {
                  UniquePairsList.add(B);
                }
                else
                {
                  int index = UniquePairsList.indexOf(UniquePairs.floor(B));
                  UniquePairsList.get(index).setWeight(UniquePairsList.get(index).getWeight() + (1/(Math.sqrt(1+CcList.size()))));
                }
              }
          }
          catch(IOException e)
          {
            System.err.println(e);
          }
        }
        catch(MessagingException x)
        {}
        catch(FileNotFoundException x)
        {}
      }
    }
    catch(IOException x)
    {
      System.err.println(x);
    }

    int k = 0;

    for(int i = 0; i < UniquePairsList.size(); i++)
    {
      try
      {
        if(!UniquePairsList.get(i).isLoop() && UniquePairsList.get(i).getWeight() > 15) //Filter out self emails
        {
          if(UniqueIndividuals.add(UniquePairsList.get(i).getFrom()))
          {
            IndividualMap.put(UniquePairsList.get(i).getFrom(),k++);
            individuals.append(IndividualMap.get(UniquePairsList.get(i).getFrom()) + " " + UniquePairsList.get(i).getFrom() + "\n");
          }

          individuals.flush();

          if(UniqueIndividuals.add(UniquePairsList.get(i).getTo()))
          {
            IndividualMap.put(UniquePairsList.get(i).getTo(),k++);
            individuals.append(IndividualMap.get(UniquePairsList.get(i).getTo()) + " " + UniquePairsList.get(i).getTo() + "\n");
          }

          interactions.append(IndividualMap.get(UniquePairsList.get(i).getFrom()) + " " + IndividualMap.get(UniquePairsList.get(i).getTo()) + " " + UniquePairsList.get(i).getWeight() +"\n");
          individuals.flush();
        }

        interactions.flush();
      }
      catch(IOException e)
      {}
    }

    for(EmailTuple i : UniqueTuples)
    {
      try
      {
        if(IndividualMap.get(i.getFrom()) != null)
        {
          messageDates.append(IndividualMap.get(i.getFrom()) + " " + i.getDate() + "\n");
          messageDates.flush();
        }
      }
      catch(IOException e)
      {}
    }

    System.out.println();
    System.out.println(duplicates + " Duplicates Removed");
    System.out.println(nulls + " Nulls Removed");
    System.out.println(spam + " Spam Removed");
    System.out.println(invalidTime + " Invalid Timestamps Removed");
  }
}
