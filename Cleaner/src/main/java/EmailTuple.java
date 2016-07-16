import java.util.Date;
import javax.mail.*;
import java.util.Arrays;
import java.util.ArrayList;

public class EmailTuple implements Comparable<EmailTuple>
{
  private String subject;
  private Date date;
  private Address to[];
  private Address from[];
  private Address cc[];
  private String body;

  public EmailTuple(String subject, Date date, Address to[], Address from[], Address cc[], String body)
  {
    this.subject = subject;
    this.date = date;
    this.to = to;
    this.from = from;
    this.cc = cc;
    this.body = body;
  }

  public String getFrom()
  {
    return this.from[0].toString();
  }

  public String getDate()
  {
    return this.date.toString();
  }

  public int compareToArray(EmailTuple other)
  {
    if(other.to.length == this.to.length)
    {
      for(int i = 0; i < other.to.length; i++)
      {
        if(this.to[i].toString().compareTo(other.to[i].toString()) != 0)
        {
          return this.to[i].toString().compareTo(other.to[i].toString());
        }
      }

      return 0;
    }

    else if(other.to.length > this.to.length)
    {
      return -1;
    }

    else
    {
      return 1;
    }
  }

  public int compareCcArray(EmailTuple other)
  {
    if(other.cc.length == this.cc.length)
    {
      for(int i = 0; i < other.cc.length; i++)
      {
        if(this.cc[i].toString().compareTo(other.cc[i].toString()) != 0)
        {
          return this.cc[i].toString().compareTo(other.cc[i].toString());
        }
      }

      return 0;
    }

    else if(other.cc.length > this.cc.length)
    {
      return -1;
    }

    else
    {
      return 1;
    }
  }

  public int compareTo(EmailTuple other)
  {
    int res = this.subject.compareTo(other.subject);
    if (res != 0)
    {
        return res;
    }

    res = this.body.compareTo(other.body);
    if (res != 0)
    {
        return res;
    }

    if((this.to != null) & (other.to != null))
    {
      res = this.compareToArray(other);
      if (res != 0)
      {
          return res;
      }
    }

    if((this.cc != null) & (other.cc != null))
    {
      res = this.compareCcArray(other);
      if (res != 0)
      {
          return res;
      }
    }

    return this.date.compareTo(other.date);
  }

}
