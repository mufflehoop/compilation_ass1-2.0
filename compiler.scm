(load "pc.scm")

;from Mayer's tutorial:
(define <whitespace>
  (const
   (lambda (ch)
     (char<=? ch #\space))))

(define <line-comment>
  (let ((<end-of-line-comment>
	 (new (*parser (char #\newline))
	      (*parser <end-of-input>)
	      (*disj 2)
	      done)))
    (new (*parser (char #\;))
	 (*parser <any-char>)
	 (*parser <end-of-line-comment>)
	 *diff *star
	 (*parser <end-of-line-comment>)
	 (*caten 3)
	 done)))

(define <sexpr-comment>
  (new (*parser (word "#;"))
       (*delayed (lambda () <Sexpr>))
       (*caten 2)
       done))

(define <comment>
  (disj <line-comment>
	<sexpr-comment>))

(define <skip>
  (disj <comment>
	<whitespace>))

(define ^^<wrapped>
  (lambda (<wrapper>)
    (lambda (<p>)
      (new (*parser <wrapper>)
	   (*parser <p>)
	   (*parser <wrapper>)
	   (*caten 3)
	   (*pack-with
	    (lambda (_left e _right) e))
	   done))))

(define ^<skipped*> (^^<wrapped> (star <skip>)))

;------------------------------------ infix comments---------------------------------------------
(define <infix-comment>
  (new (*parser (word "#;"))
       (*delayed (lambda () <Initial>))
       (*caten 2)
       done))

(define <comment_for_infix>
  (disj <line-comment>
	<infix-comment>))

(define <skip_for_infix>
  (disj <comment_for_infix>
	<whitespace>))

(define ^<skipped_infix*> (^^<wrapped> (star <skip_for_infix>)))

;------------------------------------ done dealing with whitespace & endline------------------------------------------------------

(define <digit-0-9>
  (range #\0 #\9))

(define <digit-1-9>
  (range #\1 #\9))

(define <ValidChar>
  (range #\! #\~))

(define <a-f_Char>
  (range-ci #\a #\f))

(define <ci-Char-a-z>
  (range-ci #\a #\z))


(define <Chars-for-SymbolChar>
  (new (*parser (char #\!))
       (*parser (char #\$))
       (*parser (char #\^))
       (*parser (char #\*))
       (*parser (char #\-))
       (*parser (char #\_))
       (*parser (char #\=))
       (*parser (char #\+))
       (*parser (char #\<))
       (*parser (char #\>))
       (*parser (char #\?))
       (*parser (char #\/))
       (*disj 12)
       done
       ))

(define <False>
  (new (*parser (char #\#))
       (*parser (char-ci #\f))
       (*caten 2)
       (*pack (lambda(_) #f))
       done))

(define <True>
  (new (*parser (char #\#))
       (*parser (char-ci #\t))
       (*caten 2)
       (*pack (lambda(_) #t))
       done))
		
(define <Boolean>
  (new (*parser <False>)
       (*parser <True>)
       (*disj 2)
       done))
       
(define <CharPrefix>
  (new (*parser (char #\#))
       (*parser (char #\\))
       (*caten 2)
	done))

(define  <VisibleSimpleChar>
  (new
   (*parser <ValidChar> )
   done))

(define  <NamedChar>  
  (new  (*parser (word-ci "lambda"))
	(*pack (lambda (_)  (integer->char 955)))
	(*parser (word-ci "newline"))
       	(*pack (lambda (_)  (integer->char 10)))
       	(*parser (word-ci "nul"))
     	(*pack (lambda (_)  (integer->char 0)))
       	(*parser (word-ci "page"))
       	(*pack (lambda (_) (integer->char 12)))
       	(*parser (word-ci "return"))
      	(*pack (lambda (_) (integer->char 13)))
       	(*parser (word-ci "space"))
      	(*pack (lambda (_) (integer->char 32)))
	(*parser (word-ci "tab"))
	(*pack (lambda (_) (integer->char 9)))
	(*disj 7)
	done ))

(define <HexChar>
  (new (*parser <digit-0-9>)
       (*parser <a-f_Char>)
       (*disj 2)
       (*pack (lambda(ch) (char-downcase ch)))
       done
       ))

(define  <HexUnicodeChar> 
  (new
   (*parser (char-ci #\x))
   (*parser <HexChar>) *star
   (*caten 2)
   (*pack-with (lambda(x_ch list)          
                 (integer->char
                  (string->number
                   (list->string list) 16))))
   done))

(define <Char>
  (new (*parser <CharPrefix>)
       (*parser <NamedChar>)
       (*parser <HexUnicodeChar>)
       (*parser <VisibleSimpleChar>) ;case-sensative
       (*disj 3)
       (*caten 2)
       (*pack-with (lambda(chPref ch)
		    ch))
      done))

(define <string-meta-char-from-Mayer>
  (new (*parser (word "\\\\"))
       (*pack (lambda (_) #\\))
       (*parser (word "\\\""))
       (*pack (lambda (_) #\"))
       (*disj 2)
       done))


(define <StringLiteralChar>
  (new (*parser <string-meta-char-from-Mayer>)
       (*parser <any-char>)
       (*parser (char #\"))
       (*parser (char #\\))
       (*disj 2)
       *diff
       (*disj 2)
       done))

(define <StringMetaChar>
  (new (*parser (word  "\\\\"))
       (*pack (lambda(_) "\\"))
       (*parser (word "\\\""))
       (*pack (lambda(_) "\""))
       (*parser (word "\\t"))
       (*pack (lambda(_) "\t"))
       (*parser (word "\\f"))
       (*pack (lambda(_) "\f"))
       (*parser (word "\\n"))
       (*pack (lambda(_) "\n"))
       (*parser (word "\\r"))
       (*pack (lambda(_) "\r"))
       (*disj 6)
       done))

	       
(define <StringHexChar>
  (new (*parser (char #\\))
       (*parser (char #\x))
       (*parser <HexChar>) *star
       (*caten 3)
       done))

(define <StringChar>
  (new (*parser <StringLiteralChar>) ;case sensative
       (*parser <StringMetaChar>)
       (*parser <StringHexChar>)
       (*disj 3)
       done));

(define <String> 
  (new (*parser (char #\"))
       (*parser <StringChar>) *star
       (*parser (char #\"))
       (*caten 3)
       (*pack-with (lambda(bra1 str bra2)
                    (list->string str)))
       done))


(define <Natural>
  (new 
       (*parser (char #\0)) *star
       (*parser <digit-1-9>)
       (*parser <digit-0-9>) *star
       (*caten 3)
       (*pack-with
	(lambda (zeros a s)
	  (string->number
	   (list->string
	    `(,a ,@s)))))
       
       (*parser (char #\0)) *plus
       ;(*parser <Chars_no_zero>)
       ;*not-followed-by
       (*pack (lambda (_) 0))

       (*disj 2)
       
       done))

(define <Integer>
  (new (*parser (char #\+))
       (*parser <Natural>)
       (*caten 2)
       (*pack-with
	(lambda (++ n) n))

       (*parser (char #\-))
       (*parser <Natural>)
       (*caten 2)
       (*pack-with
	(lambda (-- n) (- n)))

       (*parser <Natural>)

       (*disj 3)

       done))

(define <Fraction>
  (new (*parser <Integer>)
       (*parser (char #\/))
       (*parser <Natural>)
       (*guard (lambda (n) (not (zero? n))))
       (*caten 3)
       (*pack-with
	(lambda (num div den)
          (if (zero? num)
              0
              (/ num den))))
       done))

(define <Number>
  (new (*parser <Fraction>)
       (*parser <Integer>)
       (*disj 2)
       done))

(define <SymbolChar>
  (new (*parser <digit-0-9>)
       (*parser <ci-Char-a-z>)
       (*parser <Chars-for-SymbolChar>)
       (*disj 3)
       (*pack (lambda(ch)
                (char-downcase ch)))
      done))

(define <Symbol>
  (new (*parser <SymbolChar>) *plus
       (*pack (lambda(x) (string->symbol (list->string x))))
      done))


(define <Numbers_Char_Filter>
  (new (*parser
        (not-followed-by <Number> <Symbol>))
       done))


(define <open-Bra>
  (new (*parser (char #\( ))
       (*pack
	(lambda(_) #\( ))
       done))

(define <close-Bra>
  (new (*parser (char #\) ))
       (*pack
	(lambda(_) #\) ))
       done))

(define <ProperList>
  (new
   (*parser <open-Bra> )
   (*delayed (lambda () <Sexpr> )) *star
   (*parser <close-Bra> )
  (*caten 3)
       (*pack-with
	(lambda(a exprs c)
	  exprs))
       done))


(define <ImproperList>
  (new (*parser <open-Bra>)
       (*delayed (lambda () <Sexpr> ))  *plus
       (*parser (char #\. ))
       (*delayed (lambda () <Sexpr> ))
       (*parser <close-Bra>)
       (*caten 5)
       (*pack-with (lambda(a exps c last e)
		     (fold-right cons last exps)))
       done))

(define <Vector>
  (new (*parser (char #\# ))
       (*parser <open-Bra>)
      (*delayed (lambda () <Sexpr> )) *star
       (*parser <close-Bra> )
       (*caten 4)
       (*pack-with
	(lambda(a b sexprs d)
	  (list->vector sexprs)))
       done))

(define <Quoted>
  (new (*parser (char #\' ))
       (*delayed (lambda () <Sexpr>))
       (*caten 2)
       (*pack-with
	(lambda(ch sexp)
	  (list 'quote sexp)))
       done))

(define <QuasiQuoted>
  (new (*parser (char #\` ))
       (*delayed (lambda () <Sexpr>))
       (*caten 2)
       (*pack-with (lambda(ch sexpr)
		     (list 'quasiquote sexpr)))
       done))

(define <Unquoted>
  (new (*parser (char #\, ))
       (*delayed (lambda () <Sexpr>))
       (*caten 2)
       (*pack-with (lambda(ch sexpr)
		     (list 'unquote sexpr)))
	      done))

(define <UnquoteAndSpliced>
  (new (*parser (char #\, ))
       (*parser (char #\@ ))
        (*delayed (lambda () <Sexpr>))
       (*caten 3)
       (*pack-with (lambda(ch1 ch2 sexpr)
			    (list 'unquote-splicing sexpr)))
       done))

(define <Sexpr> 
(^<skipped*>  ;support for comment-line & whitespace 
 (new
  (*delayed (lambda () <InfixExtension>))
  (*parser <Boolean>)
  (*parser <Char>)
  (*parser <Numbers_Char_Filter>)
  (*parser <String>)  
  (*parser <Symbol>)
  (*parser <ProperList>)
      (*parser <ImproperList>)
      (*parser <Vector>)
      (*parser <Quoted>)
      (*parser <QuasiQuoted>)
      (*parser <Unquoted>)
      (*parser <UnquoteAndSpliced>)
     
       (*disj 13)
       done
       )))

(define <InfixPrefixExtensionPrefix>
  (new (*parser (char #\#))
       (*parser (char #\#))
       (*caten 2)
       (*parser (char #\#))
       (*parser (char #\%))
       (*caten 2)
       (*disj 2)
       done))


(define <Infix_Prohibited_SymbolList>
  (new (*parser (char #\+))
       (*parser (char #\-))
       (*parser (char #\*))
       (*parser (char #\*))
       (*parser (char #\*))
       (*caten 2)
       (*parser (char #\^))
       (*parser (char #\/))
       (*disj 6)
       done))

(define <PlusMinusChars>
  (new (*parser (char #\+))
       (*parser (char #\-))
       (*disj 2)
       done))

(define <MulDivChars>
  (new (*parser (char #\*))
       (*parser (char #\/))
       (*disj 2)
       done))

(define <PowChars>
  (new (*parser (char #\^))
       (*parser (word "**"))
       (*disj 2)
       done))

(define <SymbolChar_forInfixSymbol>
  (new (*parser <digit-0-9>)
       (*parser <ci-Char-a-z>)
       (*disj 2)
       (*pack (lambda(ch)
                (char-downcase ch)))
      done))


(define <InfixSymbol>
  (new
   ;(*parser
    ;    (not-followed-by <SymbolChar_forInfixSymbol> <Infix_Prohibited_SymbolList>))
   (*parser <SymbolChar_forInfixSymbol>)
   (*parser <Infix_Prohibited_SymbolList>)
   *diff
   *star
   (*pack (lambda(sym) ;(display "symbol")
            (string->symbol (list->string sym))))
   done))

(define <InfixNeg>
  (new (*parser (char #\-))
       (*delayed (lambda() <Pow_End>))
       (*caten 2)
       (*pack-with
        (lambda(char exp) ;(display "neg")
          ;(cond ((number? exp) (- exp))
                ;((list? exp) exp)
                ;((null? exp) '-)
                ;((symbol? (car exp)) exp) 
              ;(else
                `(- ,exp)));))
       done))


(define <InfixParen>
  (new (*parser (char #\( ))
       (*delayed (lambda() <Initial>)) ;*plus
       (*parser (char #\)))
       (*caten 3)
       (*pack-with (lambda(bra1 exp bra2)
                    exp))
       done))


#;(define <InfixArrayGet>
  (new
  (*delayed (lambda() <Sexpr>))
  (*parser (char #\[))
  (*delayed (lambda() <Initial>))
  (*parser (char #\]))
  (*caten 3)
  (*pack-with (lambda (par1 index par2)
		index))
  *plus
  (*caten 2)
  (*pack-with (lambda(arrName indexList)
	  		(fold-right vector-ref (list arrName (car indexList)) (cdr indexList))))
			      
  done))



(define <InfixFuncall>
  (new (*delayed (lambda() <Sexpr>)) 
       (*parser (char #\())
       (*delayed (lambda() <Initial>)) 
       (*parser (char #\,))
       (*delayed (lambda() <Initial>))
       (*caten 2)
       (*pack-with (lambda (com exp) exp))
       *star
       (*parser (char #\)))
       (*caten 5)
       (*pack-with (lambda(func par1 first args par2)
		      (cond ((null? first) `(,func))
		      ((null? args) `(,func,first))
		      (else
		      `(,func ,first ,@args)))))
       done))


(define <Pow_End>   ;L3
  (^<skipped_infix*>
   (new
    (*delayed (lambda() <InfixSexprEscape>))
    ;(*parser  <InfixArrayGet>) ;symbol
    (*parser  <InfixFuncall>)  ;symbol

    (*parser <InfixParen>)
    (*parser <Number>)
    
    (*parser <InfixNeg>)
    (*parser <InfixSymbol>)
    (*parser <epsilon>)
    (*disj 7)
    ;(*disj 8)
    done)))

(define <MulDiv> ;L2=L3(+L3)*
  (^<skipped_infix*>
   (new
   (*parser <Pow_End>)
   (*parser <PowChars>)
   (*parser <MulDiv>)
   (*parser <Pow_End>)
   (*disj 2)
   (*caten 2)
   (*pack-with (lambda (sign exps)
                 (lambda (first_element)
                   `(expt ,first_element ,exps))))
   *star
   (*caten 2)
   (*pack-with (lambda (first_exp lambda_rest_exps)
                 (fold-left (lambda (acc operator )
                              (operator acc)) first_exp lambda_rest_exps)))
   done)))


(define <AddSub> ;L1=L2(+L2)*
    (^<skipped_infix*>
     (new
      (*parser <MulDiv>)
      (*parser <MulDivChars>)
      (*parser <MulDiv>)
      (*caten 2)
      (*pack-with (lambda (sign exps)
                    (lambda (first_element)
                      `(,(string->symbol (string sign)) ,first_element ,exps))))
      *star
      (*caten 2)
      (*pack-with (lambda (first_exp lambda_rest_exps)
                    (fold-left (lambda (operator acc)
                                 (acc operator)) first_exp lambda_rest_exps)))
      done)))


(define <Initial>  ;L0=L1(+L1)*
  (^<skipped_infix*>
   (new
   (*parser <AddSub>)
   (*parser <PlusMinusChars>)
   (*parser <AddSub>)
   (*caten 2)
        (*pack-with (lambda (sign exps)
                      (lambda (first_element)
                        `(,(string->symbol (string sign)) ,first_element ,exps))))
   *star
   (*caten 2)
   (*pack-with (lambda (first_exp lambda_rest_exps)
                 (fold-left (lambda (operator acc)
                              (acc operator)) first_exp lambda_rest_exps)))
   done)))

(define <InfixExtension>
  (^<skipped_infix*>
   (new (*parser <InfixPrefixExtensionPrefix>)
       (*parser <Initial>)
       (*caten 2)
       (*pack-with
        (lambda(pre exp) exp))
       done)))


(define <InfixSexprEscape>
  (new (*parser <InfixPrefixExtensionPrefix>)
       (*parser <Sexpr>)
       (*caten 2)
       (*pack-with (lambda(pre exp)
                    exp))
       done))



;---------------------------------------------------------------------------------------------

#;(define <InfixMul>
  (new	 (*parser <Number>)
	 (*parser (char #\*))
	 (*parser <Number>)
	 (*caten 3)
	 (*pack-with (lambda(exp1 ch exp2)
		       (list ch exp1 exp2)))
	 done))

#;(define <InfixAdd>
  (new	 (*parser <InfixMul>)
	 (*parser (char #\+))
	 (*parser <InfixMul>)
	 (*caten 3)
	 (*pack-with (lambda(exp1 ch exp2)
		       (list ch exp1 exp2)))
	 done))

#;(define <InfixSub>
  (new	 (*parser <InfixAdd>)
	 (*parser (char #\-))
	 (*parser <InfixAdd>)
	 (*caten 3)
	 (*pack-with (lambda(exp1 ch exp2)
		       (list ch exp1 exp2)))
	 done))


#;(define <Chars_no_Numbers>
  (new (*parser <any-char>)
       (*parser <digit-0-9>)
       *diff
       done))

#;(define <Chars_no_zero>
  (new (*parser <any-char>)
       (*parser (char #\0))
       *diff
       done))

#;(define <test1>
  (new (*parser <SymbolChar>)
       (*parser <InfixSymbolList>)
       *diff
       *star
       (*pack (lambda(x) (string->symbol (list->string x))))
       done))


#;(define <a>
  (new (*parser <a-f_Char>)
       *star
       (*parser (char #\z))
       *not-followed-by

;*not-followed-by       
  done))

