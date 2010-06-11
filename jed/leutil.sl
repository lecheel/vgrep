%%
%%  lechee utility functions which Must be available (e.g., autoload)
%%

%   ll_mini_init many thanks Guenter.Milde implement
%
%
define get_token()
{
   variable vpat = "0-9A-Z_a-z";
#ifdef VMS
   vpat = strcat (vpat, "$");
#endif
   push_spot ();
   skip_white ();
   bskip_chars (vpat);
   push_mark ();
   skip_chars (vpat);
%   vpat = bufsubstr ();		% leave on the stack
   bufsubstr();
   pop_spot ();
}


%
%
%
static variable ll_mini_init_str = "";
define ll_read_mini(prompt, init)
{
   ll_mini_init_str = init;
   return read_mini(prompt, init, "");
}

define ll_mini_init()
{
   delete_line();
   insert(ll_mini_init_str);
}
