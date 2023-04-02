module templatenest.nest;

import std.path;
import std.file;

import std.conv;

import std.string;

import std.algorithm;
import std.array;

struct defvaltype
{

    defvaltype[string] level;
    defvaltype[] array;
    string val;

   void  opIndexAssign(string val,string key)
    {
        if (level == null)
            level = new defvaltype[string];
        
        level[key] = defvaltype();
        level[key].val=val;
    }

    void  opIndexAssign(string[string] val,string key)
    {
        if (level == null)
            level = new defvaltype[string];

        level[key] = defvaltype();
        defvaltype *l= &level[key];
            foreach (k,v;val)
            {
                l.level[k] = defvaltype();
                l.level[k].val = v;
            }
       
    }

    void  opIndexAssign(string[string][] arrayofhash,string key)
    {
        
        if (level == null)
            level = new defvaltype[string];

        level[key] = defvaltype();
        defvaltype *l= &level[key];

        foreach(i,hash;arrayofhash)
        {
            
            defvaltype level1 = defvaltype();
            level1.level = new defvaltype[string];
            foreach (k,v;hash)
            {
                level1.level[k] = defvaltype();
                level1.level[k].val = v;
            }
            l.array~=level1;
        }
       
    }

    string toString()
    {

        if (level != null)
        {
            return "{"~join(map!(a => "\""~a~"\":" ~ level[a].toString())(level.keys), ",")~"}";   
           
        }
        else
        if (array != null)
        {
            return "["~join(map!(a => a.toString())(array), ",")~"]";        
        }
        else
        if (val != null)
        {
           return"\""~  val ~"\""; 
        }
        return "Nil";
    }

   /* 

    void  opIndexAssign(string[string] val,string key)
    {
        if (level == null)
            level = new defvaltype[string];
        foreach (k,v;val)
        {
            level[key][k] = v;
        }
       
    }

     void opAssign(defvaltype * val)
    {
        this= *val ;
    }

   

    

     void opAssign(defvaltype[] array)
    {
        this.array = array;
    }

     void opAssign(defvaltype[string] level)
    {
        this.level = level;
    }*/

    void opAssign(string val)
    {
        this.val = val ;
    }

     void opAssign(string[string] level)
    {
        foreach(k,v;level)
        {
            this.level[k].val = v;
        }
        
    }


   
    /*~ this()
    {
        //if (level != null)
        //    delete level;
        //if (array != null)
        //    delete array;
    }*/
};

class Nest
{


     public:
    //has Str $.template_dir is rw;
    string template_dir;
    //has Str $.template_ext is rw = '.html';
    string template_ext = ".html";
    //has% .template_hash is rw;
    defvaltype template_hash;

    //has% .defaults is rw;
    defvaltype defaults;
    //subset Char of Str where.chars == 1 || .chars == 0;

    //has Char $.defaults_namespace_char is rw = '.';
    string defaults_namespace_char = ".";
    string [2] comment_delims_defaults = [ "<!--", "-->"];
    //my @comment_delims_defaults[2] = '<!--', '-->';
    //has Str @.comment_delims[2] is rw;
    string [2] comment_delims;

    //my @token_delims_defaults[2] = '<%', '%>';
    string [2] token_delims_defaults= [ "<%", "%>" ];
    //has Str @.token_delims[2] is rw;
    string [2] token_delims;

    //has Bool $.show_labels is rw = False;
    bool show_labels = false;
    //has Str $.name_label is rw = 'TEMPLATE';
    string name_label = "TEMPLATE";
    //has Bool $.fixed_indent is rw = False;
    bool fixed_indent = false;
    //has Bool $.die_on_bad_params is rw = False;
    bool die_on_bad_params = false;
    //has Char $.escape_char is rw = '\\';
    string escape_char  = "\\";
    

    

    bool indexes = true;
    string die = "";

    string conv_error = "";
    string output = "";
    struct param_locations_type
    {
        size_t p0;
        size_t p;
        string name;

    };
    struct location_info {

        string escape_char;
        string file;
        bool set  = false;
       param_locations_type[][] loc   ;
    };
     location_info [string] param_locations;

this()
{
    template_hash = defvaltype();
    defaults = defvaltype();
   // template_hash.level = new defvaltype[string];
   // defaults.level = new defvaltype[string];
    param_locations = new location_info[string];
   
}

string rendertop(ref const defvaltype  comp )
{
    
    try
    {
        return render(comp);
    }
    catch (Exception  message)
    {
       // die = message;
        return "";
    }
}
import std.stdio;
string render(ref const defvaltype comp)
{
    //self.comment_delims = @comment_delims_defaults unless grep{ $_ }, @!comment_delims;
   //self.token_delims = @token_delims_defaults unless grep{ $_ }, @!token_delims;
    if (comment_delims[0]=="" || comment_delims[0] is null)
        comment_delims[] = comment_delims_defaults;
      //  std::copy(&comment_delims_defaults[0], &comment_delims_defaults[2], comment_delims);
    // comment_delims = comment_delims_defaults;
    if (token_delims[0]=="" || token_delims[0] is null)
        //token_delims = token_delims_defaults;
        token_delims[] = token_delims_defaults;
        //std::copy(&token_delims_defaults[0], &token_delims_defaults[2], token_delims);
    die = "";
    string html;
    if (comp.array!=null && comp.array.length != 0)
        html = render_array(comp.array);
    else if (comp.level != null && comp.level.length != 0)
        html = render_hash(comp.level);
    else
        html = comp.val;
    return html;
}



string render_hash(ref const defvaltype[string] h) {
    //#say "render hash: " ~ %h<NAME>;
    string template_name = h[name_label].val;

    if (template_name=="")
    {
        die = "Encountered hash with no name_label(\"" ~ name_label ~ "\")";
        throw new Exception(die);
       
    }

    string [string] param;
    foreach (k,v ; h)
    {
        if (k  == name_label)
            continue;
        param[k] = render( v);
    }

    string template1 = get_template( template_name );
    string html = fill_in( template_name, template1, param );

    if (show_labels) {

        const string  ca = comment_delims[0];
        const string  cb = comment_delims[1];

        html = ca~" BEGIN "~template_name~" "~cb~"\n"~ html ~ "\n" ~ ca ~ " END " ~ template_name ~ " " ~ cb ~ "\n";
    }

    return html;

}



string render_array(const ref defvaltype[] arr) {
    //#say "render array";
    string html = "";
    foreach ( v ; arr) {
        html ~= render(v);
    }
    return html;
}





void remove_trailing_whitespace(string s)
{
    if (s.length == 0)
        return;
    size_t p = s.length-1;
    while (p >=0)
    {
        if (s[p] == 32 || s[p] == 10 || s[p] == 13 || s[p] == 9)
        {
            p--;
        }
        else
            break;
    }
    s = s [0.. p + 1];


}



string get_template(string template_name) {
    

    string template1 = "";
    if (template_hash.level!=null && template_hash.level.length!=0) {
       // try {
            auto v = template_name in template_hash.level;
            if (v is null)
            {
                die = "template_hash does not have this key:" ~ template_name;
                throw new Exception(die);
            }
            if (v.array.length == 0 && v.level.length == 0)
                template1 = v.val;
       // }
        

       
    }
    else { 
        auto p =  buildPath(template_dir , template_name~ template_ext);
       
        try {
          auto data = template_name in param_locations;
          if (data !is null)
          {
              template1 = data.file;
          }
          else
          {
              template1 =cast (string) read(p);
              param_locations[template_name] = location_info();
              param_locations[template_name].file = template1;
          }
          
        }
        catch (FileException o)
        {
            die = "could not open " ~ p ~ " reason:" ~ to!string(o.errno);
            throw new Exception(die);
        }
    }
       
    remove_trailing_whitespace(template1);
    return template1;
}



string[] split(const string s, const string del)
{
    string[] res;
    auto p = indexOf(s,del);
    size_t p0 = 0;
    if (p == -1)
    {
        res~=(s);
        return res;
    }
    while (p != -1)
    {
        res~=s[p0..p];
        p0 = p+ del.length;
        p = indexOf(s,del, p0);
    }
    if (p0 < s.length)
    {
        res~=s[p0..$];
    }
    return res;
  
}


string[] sort(const ref string[] v)
{
    string[] res = v.dup;
    res.sort();
    return res;
}

string [] params(string template_name) {
    
   


    string esc = escape_char;
    string template1 = get_template(template_name);
    string [] frags = split(template1, esc ~ esc); // $template.split(/ $esc$esc / );
   
    string [] rem;
    foreach ( f ; frags)
    { 
       string [] res = params_in(f);
        foreach ( s ; res)
        {
            rem~=(s);
        }
    }
    
    return sort(rem);
}


void skip_space(ref string s, ref size_t  p)
{
  
    while (p < s.length)
    {
        if (s[p] == 32  || s[p] == 9)
        {
            p++;
        }
        else
            break;
    }
}
// points to the first space or non space if there is no space
void skip_space_backwards(string s, ref size_t  p)
{
    p--;
    while (p >=0)
    {
        if (s[p] == 32 || s[p] == 9)
        {
            p--;
        }
        else
            break;
    }
    p++;
}

void set_indent_all(ref string s, const string indent)
{
    size_t p = 0;
    string o;
    bool e = false;
    size_t p0 = p;
    while (p < s.length)
    {
        
        if (s[p] == 13)
        {
            p++;
            e = true;
            if (p < s.length && s[p] == 10)
            {
                p++;
            }
        }
        else if (s[p] == 10)
        {
            p++;
            e = true;
        }
        else
            p++;

        if (e)
        {
            o ~= s[p0.. p] ~ indent;
            e = false;
            p0 = p;
        }
    }
    if (p0 < s.length)
    {
        o ~= s[p0..$];
    }

    s = o;

}

string  died()
{
    string o = die;
   
    return die;
}

string replace_all(const string s, const string r, const string  replacement)
{
    string res;
    res.reserve(s.length * 2);
    auto p = s.indexOf(r);
    size_t p0 = 0;
    if (p == -1)
    {
        return s;
    }
    while (p != -1)
    {
        res~= s[p0.. p] ~ replacement;
        p0 = p + r.length;
        p = s.indexOf(r, p0);
    }
    if (p0 < s.length)
    {
        res ~= s[p0..$];

    }
    return res;

}

string join(const string [] s, const string  del)
{
    string ss ;
    bool first = true;
    foreach (s1;s)
    {
        if (first)
        {
            ss ~= s1;
            first = false;
        }
        else
        {
            ss ~= del;
            ss ~=  s1;
        }

    }
    return ss;

}


string fill_in(const string  template_name, const string  template1, const string[string]  params) {

    string esc = escape_char;
    string[] frags;
   
    
    if (!esc.empty()){
        frags = split(template1, esc~esc );
       
    }
    else {
        frags~=(template1);
       
    }

   

    bool [string] params_replaced;
    foreach (k ; params)
    {
        params_replaced[k] = false;
      
    }

    

   // for (auto& kv : params)
    {
     //   const string& param_name = kv.first;


     //   const string& param_val = kv.second;

        auto iter = template_name in param_locations;

        if (iter is null || !iter.set || ! indexes  || iter.escape_char != esc)
        {
            int i = 0;
            if (iter is null)
                param_locations[template_name] = location_info();
            else if (iter.escape_char!= esc)
            {
                string f = param_locations[template_name].file;
                param_locations[template_name] = location_info();
                param_locations[template_name].file = f;
            }

            location_info  *locations = &param_locations[template_name];
            locations.escape_char = esc;
            locations.set = true;
           
            foreach (ref  f ; frags) {
                param_locations_type[] locationsinfrag;
               
                size_t p = 0;
                while (f.length > p)
                {
                    bool found;
                    size_t p0;
                    string param_name_found;
                    if (!token_regex(param_name_found, f, p0, p, false, found))
                        break; 
                    {
                        param_locations_type l;
                        l.p0 = p0;
                        l.p = p;
                        l.name = param_name_found;
                            
                        locationsinfrag~=(l);
                    }
                }



                locations.loc~=  locationsinfrag;
                i++;

            }
        }
        location_info * locations = &param_locations[template_name];
        if (fixed_indent) { //if fixed_indent we need to add spaces during the replacement
            int fragno = 0;
            bool replaced = false;
            foreach (ref f ; frags) {
               
                string fragout;
                fragout.reserve(f.length*2);
                size_t copied_until = 0;
               

                //for @frags.keys->$i {

                size_t p = 0;

                // my Regex $rx = self!token_regex($param_name);
                 //my Match @spaces_repl = @frags[$i] ~~m:g / (<-[\S\r\n]>*) < $rx > / ;

                const param_locations_type[] locationsinfrag = locations.loc [fragno] ;
                int locationno = 0;
                while (f.length > p)
                {
                    //size_t p0 = p;
                    //skip_space(f, p);
                    //size_t p1 = p;
                    //string sp = f.substr(p0, p1 - p0);
                    bool found;
                    size_t p0;
                   


                    if (locationsinfrag.length == locationno)
                        break;
                    const param_locations_type loc = locationsinfrag[locationno];

                    p0 = loc.p0;
                    p = loc.p;
                    const string  param_name_found = loc.name;

                   // if (!token_regex(param_name_found, f, p0,p, false,found))
                    //    break;
                   // typeof i;
                    string defaultval;
                    auto i = (param_name_found in params);
                    if ( i!is null)
                    {

                    }
                    else if (defaults.level.length!=0) 
                    {
                        const string char1 = defaults_namespace_char;
                        string [] parts = [ param_name_found ];
                        if (!char1.empty())
                            parts = split(param_name_found, char1);

                        defaultval = get_default_val(defaults, parts);
                      
                    }
                   // if (i!= params.end() || !defaultval.empty())
                    {
                        size_t ps = p0;
                        skip_space_backwards(f,ps);
                        string sp = f[ps.. p0];
                        //say "spaces_repl: " ~Dump(@spaces_repl);
                        //say "while";
                        //my Match $repl = shift @spaces_repl;
                        //my Match $sp = $repl.list[0];
                        string param_val = defaultval;  
                        if (i !is null )
                            param_val = *i;

                        string param_out = param_val;
                        //say "param out before: " ~$param_out;
                        //$param_out ~~s:g / \n / \n$sp / ;
                        set_indent_all(param_out, sp);
                        param_out = sp ~ param_out;
                        //say "param out after: " ~$param_out;

                        if (esc.length != 0)
                        {
                            if (ps >= esc.length && f[ps - esc.length.. ps] == esc)
                            {

                            }
                            else
                            {
                                if (i !is null)
                                {
                                    params_replaced[param_name_found] = true;
                                   
                                }
                                replaced = true;
                                fragout ~= f[copied_until.. ps] ~ param_out;
                                copied_until = p;
                                //f.replace(ps, p - ps, param_out);
                                //p = ps + param_out.length;
                            }
                        }
                        else
                        {
                            if (i !is null)
                            {
                                params_replaced[param_name_found] = true;
                              
                            }
                            replaced = true;
                            fragout ~= f[copied_until.. ps]  ~ param_out;
                            copied_until = p;

                           // f.replace(ps, p - ps, param_out);
                           // p = ps + param_out.length;

                        }

                        /*  if (!esc.empty()) {

                              $replaced = True if @frags[$i] ~~s / <!after $esc> $repl / $param_out / ;
                          }*/

                    }
                    locationno++;
                }
                
                if (replaced)
                {
                    fragout = fragout ~  f[copied_until.. $];
                    f = fragout;
                }

                fragno++;
            }
        }
        else {
            int fragno = 0;
            bool replaced = false;
           
          
            foreach (ref f ; frags) {
                //say "for ffk";
                //my Regex $rx = self!token_regex($param_name);
                //say "regex: " ~$rx.gist;
                //say "frag: " ~@frags[$i];
                //say "param_val: " ~$param_val.gist;
                //say "param_name: " ~$param_name.Str;
                //say "m: " ~$m.gist;
                size_t p = 0;
                const param_locations_type [] locationsinfrag = locations.loc[fragno];
                string fragout;
                fragout.reserve(f.length * 2);
                size_t copied_until = 0;
                int locationno = 0;
                
               
                while (f.length > p)
                {
                   
                    size_t p0;
                   
                    if (locationsinfrag.length == locationno)
                        break;

                    
                    const param_locations_type *  loc = &locationsinfrag[locationno];
                   
                    p0 = loc.p0;
                    p = loc.p;

                   
                    const string param_name_found = loc.name;
                   // if (!token_regex(param_name_found, f, p0,p, false,found))
                    //    break;
                    auto i = param_name_found in params;
                   
                    if (i !is null )
                    {
                        params_replaced[param_name_found] = true;
                        replaced = true;
                        const string param_val = *i;
                       
                        fragout ~= f[copied_until.. p0 ] ~ param_val;
                       
                        copied_until = p;
                       
                     
                       // f.replace(p0, p - p0, param_val);
                       // p = p0 + param_val.length;
                    }
                    else
                    {

                        if (defaults.level.length != 0) {
                            const string char1 = defaults_namespace_char;
                            string[] parts = [ param_name_found ];
                            if (char1.length!=0)
                                parts = split(param_name_found, char1);

                            string val = get_default_val(defaults, parts);
                            fragout ~= f[copied_until.. p0 ] ~ val;

                            copied_until = p;
                        }
                        else // empty
                        {
                            replaced = true;
                            fragout ~= f[copied_until.. p0 ];

                            copied_until = p;
                        }

                    }
                    locationno++;
                }
               
                if (replaced)
                {
                    fragout = fragout ~ f[copied_until.. $];
                    f =fragout;
                }
                //replaced = True if @frags[$i] ~~s:g / <$rx> / $param_val / ;
                //say "end of ffk";
                fragno++;
            }
        }
       

    }
  
    if (die_on_bad_params)
        foreach ( k,v ; params_replaced)
            if (!v) {
                die = "Could not replace template param '" ~ k  ~ "': token does not exist in template '" ~ template_name ~ "'";
                throw new Exception(die);
              
            }
        

        if (!esc.empty()){
            foreach (ref f ; frags) {
                
                f = replace_all(f, esc, "");
                //@frags[$i] ~~s:g / $esc//;
            }
        }

    const string  text = !esc.empty() ? join(frags,esc) :(frags[0]);
    return text;
}




bool skip_whitespace(const string s, ref size_t p)
{
    size_t pc = p;
    while (s.length > p)
    {
        if (s[p] == 32 || s[p] == 10 || s[p] == 13 || s[p] == 9)
        {
            p++;
        }
        else
            break;
    }
    return pc != p;

}

bool find_next_whitespace(const string s, ref long  p)
{
    size_t pc = p;
  
    while (s.length > p)
    {
        if (s[p] == 32 || s[p] == 10 || s[p] == 13 || s[p] == 9)
        {
           
            return true;
        }
        else
            p++;
    }
    p = pc;
    return false;

}
string[] params_in(const string text) {

    string esc = escape_char;
    string tda = token_delims[0];
    string tdb = token_delims[1];
    string [] keys;
    
   
        size_t p = 0;
        while (text.length > p)
        {
            auto p2 = text.indexOf(tda, p);
            if (p2 == -1)
                return keys;
            if (esc.length!=0)
                if (p2 >= esc.length && text[p2 - esc.length..p2] == esc)
                {
                    p = p2;
                    p += tda.length;
                    continue;
                }
            p = p2;
            p += tda.length;
            if(!skip_whitespace(text, p))
                continue;
            p2 = p;
            if (!find_next_whitespace(text,  p2))
                continue;
            size_t p3 = p2;
            if (!skip_whitespace(text, p3))
            {
                continue;
            }
            if (text[p3.. p3+ tdb.length] != tdb)
                continue;

            keys~=text[p..p2];
            p = p3 + tdb.length;
        }

   
        return keys;
}




string shift(ref string[] v) {
    if (v.length!=0)
    {
        string f = v[0];
        v = v[1..$];
        return f;
    }
    else
    {
        return "";
    }
}


string get_default_val(const ref defvaltype  def, const string [] parts)
{
    if (parts.length == 1)
    {
        auto f = parts[0] in def.level;
        string val = f !is null  ? f.val : "";
        return val;
    }
    else {
        string [] partsmod= parts.dup;
        string ref_name = shift (partsmod);

        auto new_def = ref_name in def.level;
        //my% new_def = % def{ $ref_name };
        if (new_def is null || new_def.level.length == 0)
            return "";

        //return '' unless % new_def;
        return get_default_val((*new_def), partsmod);
    }


}



// returns true if searching can be continued
bool token_regex(ref string param_name, const string text, ref size_t  p0,ref size_t  p, bool fixed_pos,ref bool  found)
{
    const string  esc = escape_char;
    const string tda = token_delims[0];
    const string  tdb = token_delims[1];

   
    found = false;


    if (text.length > p)
    {
        long p2;
        if (fixed_pos)
        {
            if (text[p.. p+tda.length] != tda)
                return false;
            p2 = p;
        }
        else
           p2 = text.indexOf(tda, p);
       
        if (p2 == -1)
            return false;
        p0 = p2;
        if (esc.length != 0)
            if (p2 >= esc.length && text[p2 - esc.length..p2] == esc)
            {
                p = p2;
                p += tda.length;
                return true;
            }
        p = p2;
        p += tda.length;
        if (!skip_whitespace(text, p))
            return true;
        p2 = p;
        if (!find_next_whitespace(text, p2))
            return true;
        size_t p3 = p2;
        if (!skip_whitespace(text, p3))
        {
            return true;
        }
        if (text [p3.. p3+ tdb.length] != tdb)
            return true;


        param_name = text[p.. p2];
       /* if (text.substr(p, p2 - p) != param_name && !param_name.empty())
        {
            return true;
        }*/

        p = p3 + tdb.length;
        found = true;
        return true;
    }
    return false;
}
import std.datetime.stopwatch: benchmark;

static void benchmarking()
{
        auto nest = new Nest();
          nest.template_dir = r"D:\m\cpp\TemplateNest\tests\";
          nest.fixed_indent = true;
          nest.name_label = "NAME";
          nest.indexes = true;
          defvaltype val ;
          //val.level = new defvaltype[string];
          //val.level["NAME"] =  defvaltype();
          val["NAME"]= "page";
          val["contents"] = [[
			"NAME":  "box",
			"title":  "First nested box"
          ], [
			"NAME":  "box",
			"title":  "Second  nested box"
          ]];

          writeln(val.toString());
          writeln(nest.render(val));


         auto r = benchmark!( {nest.render(val);}  )(50_000);
         writeln(r);

}

unittest
    {
        benchmarking();

    }

}



