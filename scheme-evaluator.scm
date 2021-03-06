(#%require (only racket/base
                 time error))

;; Start Test Modern Programming Paradigms


;;
;; Metodo auxiliares para la estructura circula, las ideas fueron tomadas de https://github.com/TaylanUB/scheme-srfis/
;;

;Metodo ausiliar para obtener el ultimo para, su usa en la lista circula
(define (last-pair lis)
  (let lp ((lis lis))
    (let ((tail (cdr lis)))
      (if (pair? tail) (lp tail) lis))))

;Metodo ausiliar para crear una lista de numeros consecutivos, ej: 3 (3 2 1 0)
(define (iota count)
  (let loop ((n count) (r '()))
    (if (= n -1)
        (reverse r)
        (loop (- n 1)
              (cons n r)))))

;; Para printear la lista, tomado de http://srfi.schemers.org/srfi-1/mail-archive/msg00096.html
(define (circular-list-length lst)
  "Return the number of distinct elements of circular list LST."
  (let ((tortoise lst)
        (hare lst)
        (tortoise-advance #t)
        (len 0))
    ;; Find a member of the list guaranteed to be within the cycle, and
    ;; compute length if list turns out to be non-circular.
    (do ()
        ((null? hare))
      (set! hare (cdr hare))
      (set! len  (+ len 1))
      (set! tortoise-advance (not tortoise-advance))
      (if tortoise-advance
           (set! tortoise (cdr tortoise)))
      (if (eq? hare tortoise)
          (begin
            (set! hare '())
            (set! len 0))))

    (if (and (not (null? lst))
             (zero? len))
        (begin
          ;; Find period of cycle.
          (set! hare (cdr tortoise))
          (set! len 1)
          (do ()
              ((eq? hare tortoise))
            (set! hare (cdr hare))
            (set! len (+ len 1)))

          ;; Give hare a head start from the start of the list equal to the
          ;; loop size.  If both move at the same speed they must meet at
          ;; the nexus because they are in phase, i.e. when tortoise enters
          ;; the loop, hare must still be exactly one loop period
          ;; ahead--but that means it will be pointing at the same list
          ;; element.
          (set! tortoise lst)
          (set! hare (list-tail lst len))
          (do ()
              ((eq? tortoise hare))
            (set! hare (cdr hare))
            (set! tortoise (cdr tortoise))
            (set! len (+ len 1)))))
    len))

;;
;; make-ring
;;
;; (define r (make-ring 3))(display-ring r)(display-ring (cdr r))
;;

; Ejer 2.a
(define (make-ring count)
  (let ((ans (iota count)))
    (set-cdr! (last-pair ans) ans)
    ans)
)

; Ejer 2.c
(define (display-ring ring)
  (let recur ((lis ring) (k (circular-list-length ring)))
    (if (zero? k) (display '...)
	(begin
          (display " ")
          (display (car lis))
          (recur (cdr lis) (- k 1))
         )    
    )
  )
  'ok)

; Ejer 3.a
; (list-of x (* x x) '(1 2 3 3))

;comprobar si es uan expresion de tipo list-of
(define (list-of? exp) (tagged-list? exp 'list-of))

;Obtener los argumentos
(define (get-var exp)(car (list-of-args (operands exp))))
(define (get-transform-exp exp)(car (cdr (list-of-args (operands exp)))))
(define (get-input-exp exp)(car (cdr (cdr (list-of-args (operands exp))))))

;obtener la lista de agumentos sin evaluar las expreciones
(define (list-of-args exps)
  (if (no-operands? exps)
      '()
      (cons (first-operand exps)
            (list-of-args (rest-operands exps)))))

;metodo auxiliar para llamar al list-of
(define (eval-list-of exp env)
  (let temp ((var (get-var exp)) (transform-exp (get-transform-exp exp)) (input-exp (get-input-exp exp)))(list-of var transform-exp input-exp env)))

(define (list-of var transform-exp input-exp env)
  (let recur ((lis (eval input-exp env)))
      (if (eq? lis '()) '()	       
           (cons (eval transform-exp (extend-environment (list var) (list (car lis)) env)) (recur (cdr lis))))))


;; End Test Modern Programming Paradigms


;;
;;toegevoegd
;;
(define true #t)
(define false #f)

;;
;; zie deel 1a p. 37
;;
(define apply-in-underlying-scheme apply)

;;
;; zie deel 1a p. 6/7
;;
(define (eval exp env)
  (cond ((self-evaluating? exp) exp)
        ((variable? exp) (lookup-variable-value exp env))
        ((quoted? exp) (text-of-quotation exp))
        ((assignment? exp) (eval-assignment exp env))
        ((definition? exp) (eval-definition exp env))
        ((if? exp) (eval-if exp env))
        ((lambda? exp)
         (make-procedure (lambda-parameters exp)
                         (lambda-body exp)
                         env))
        ((begin? exp) 
         (eval-sequence (begin-actions exp) env))
        ((cond? exp) (eval (cond->if exp) env))
        ((list-of? exp) (eval-list-of exp env));Agregar aqui para que evalue la exprecion list-of de forma personalizada
        ((application? exp)
         (apply (eval (operator exp) env)
                (list-of-values (operands exp) env)))
        (else
         (error "Unknown expression type -- EVAL" exp))))

;;
;; zie deel 1a p. 8/9
;;
(define (apply procedure arguments)
  (cond ((primitive-procedure? procedure)
         (apply-primitive-procedure procedure arguments))
        ((compound-procedure? procedure)
         (eval-sequence
           (procedure-body procedure)
           (extend-environment
             (procedure-parameters procedure)
             arguments
             (procedure-environment procedure))))
        (else
         (error
          "Unknown procedure type -- APPLY" procedure))))

;;
;; zie deel 1a p. 10operator
;;
(define (list-of-values exps env)
  (if (no-operands? exps)
      '()
      (cons (eval (first-operand exps) env)
            (list-of-values (rest-operands exps) env))))

;;
;; zie deel 1a p. 11
;;
(define (eval-assignment exp env)
  (set-variable-value! (assignment-variable exp)
                       (eval (assignment-value exp) env)
                       env)
  'ok)

;;
;; zie deel 1a p. 12
;;
(define (eval-definition exp env)
  (define-variable! (definition-variable exp)
                    (eval (definition-value exp) env)
                    env)
  'ok)

;;
;; zie deel 1a p. 13
;;
(define (true? x)
  (not (eq? x false)))

(define (false? x)
  (eq? x false))

(define (eval-if exp env)
  (if (true? (eval (if-predicate exp) env))
      (eval (if-consequent exp) env)
      (eval (if-alternative exp) env)))

;;
;; zie deel 1a p. 14
;;
(define (eval-sequence exps env)
  (cond ((last-exp? exps) (eval (first-exp exps) env))
        (else (eval (first-exp exps) env)
              (eval-sequence (rest-exps exps) env))))

;;
;; zie deel 1a p. 15
;;
(define (self-evaluating? exp)
  (cond ((number? exp) true)
        ((string? exp) true)
        (else false)))

;;
;; zie deel 1a p. 16
;;
(define (tagged-list? exp tag)
  (if (pair? exp)
      (eq? (car exp) tag)
      false))

(define (quoted? exp)
  (tagged-list? exp 'quote))

(define (text-of-quotation exp) (cadr exp))

;;
;; zie deel 1a p. 17
;;
(define (variable? exp) (symbol? exp))

;;
;; zie deel 1a p. 18
;;
(define (assignment? exp)
  (tagged-list? exp 'set!))

(define (assignment-variable exp) (cadr exp))

(define (assignment-value exp) (caddr exp))

;;
;; zie deel 1a p. 19/20
;;
(define (definition? exp)
  (tagged-list? exp 'define))

(define (definition-variable exp)
  (if (symbol? (cadr exp))
      (cadr exp)
      (caadr exp)))

(define (definition-value exp)
  (if (symbol? (cadr exp))
      (caddr exp)
      (make-lambda (cdadr exp)
                   (cddr exp))))

;;(list-of x (* x x) '(1 2 3))
;; zie deel 1a p. 21
;;
(define (if? exp) (tagged-list? exp 'if))

(define (if-predicate exp) (cadr exp))

(define (if-consequent exp) (caddr exp))

(define (if-alternative exp)
  (if (not (null? (cdddr exp)))
      (cadddr exp)
      'false))

(define (make-if predicate consequent alternative)
  (list 'if predicate consequent alternative))

;;
;; zie deel 1a p. 22
;;
(define (lambda? exp) (tagged-list? exp 'lambda))

(define (lambda-parameters exp) (cadr exp))
(define (lambda-body exp) (cddr exp))

(define (make-lambda parameters body)
  (cons 'lambda (cons parameters body)))

;;
;; zie deel 1a p. 23/24
;;
(define (cond? exp) (tagged-list? exp 'cond))

(define (cond-clauses exp) (cdr exp))

(define (cond-else-clause? clause)
  (eq? (cond-predicate clause) 'else))

(define (cond-predicate clause) (car clause))

(define (cond-actions clause) (cdr clause))

(define (cond->if exp)
  (expand-clauses (cond-clauses exp)))

(define (expand-clauses clauses)
  (if (null? clauses)
      'false
      (let ((first (car clauses))
            (rest (cdr clauses)))
        (if (cond-else-clause? first)
            (if (null? rest)
                (sequence->exp (cond-actions first))
                (error "ELSE clause isn't last -- COND->IF"
                       clauses))
            (make-if (cond-predicate first)
                     (sequence->exp (cond-actions first))
                     (expand-clauses rest))))))

;;
;; zie deel 1a p. 25
;;
(define (begin? exp) (tagged-list? exp 'begin))

(define (begin-actions exp) (cdr exp))

(define (last-exp? seq) (null? (cdr seq)))

(define (first-exp seq) (car seq))

(define (rest-exps seq) (cdr seq))

(define (sequence->exp seq)
  (cond ((null? seq) seq)
        ((last-exp? seq) (first-exp seq))
        (else (make-begin seq))))

(define (make-begin seq) (cons 'begin seq))

;;
;; zie deel 1a p. 26
;;
(define (application? exp) (pair? exp))

(define (operator exp) (car exp))

(define (operands exp) (cdr exp))

(define (no-operands? ops) (null? ops))

(define (first-operand ops) (car ops))

(define (rest-operands ops) (cdr ops))

;;
;; zie deel 1a p. 27number?
;;
(define (make-procedure parameters body env)
  (list 'procedure parameters body env))

(define (compound-procedure? p)
  (tagged-list? p 'procedure))

(define (procedure-parameters p) (cadr p))

(define (procedure-body p) (caddr p))

(define (procedure-environment p) (cadddr p))

;;
;; zie deel 1a p. 29
;;
(define (enclosing-environment env) (cdr env))

(define (first-frame env) (car env))

(define the-empty-environment '())

;;
;; zie deel 1a p. 30
;;
(define (extend-environment vars vals base-env)
  (if (= (length vars) (length vals))
      (cons (make-frame vars vals) base-env)
      (if (< (length vars) (length vals))
          (error "Too many arguments supplied" vars vals)
          (error "Too few arguments supplied" vars vals))))

;;
;; zie deel 1a p. 31
;;
(define (make-frame variables values)
  (cons variables values))

(define (frame-variables frame) (car frame))
(define (frame-values frame) (cdr frame))

(define (add-binding-to-frame! var val frame)
  (set-car! frame (cons var (car frame)))
  (set-cdr! frame (cons val (cdr frame))))

;;
;; zie deel 1a p. 32
;;
(define (lookup-variable-value var env)
  (define (env-loop env)
    (define (scan vars vals)
      (cond ((null? vars)
             (env-loop (enclosing-environment env)))
            ((eq? var (car vars))
             (car vals))
            (else (scan (cdr vars) (cdr vals)))))
    (if (eq? env the-empty-environment)
        (error "Unbound variable" var)
        (let ((frame (first-frame env)))
          (scan (frame-variables frame)
                (frame-values frame)))))
  (env-loop env))

;;
;; zie deel 1a p. 33
;;
(define (set-variable-value! var val env)
  (define (env-loop env)
    (define (scan vars vals)
      (cond ((null? vars)
             (env-loop (enclosing-environment env)))
            ((eq? var (car vars))
             (set-car! vals val))
            (else (scan (cdr vars) (cdr vals)))))
    (if (eq? env the-empty-environment)
        (error "Unbound variable -- SET!" var)
        (let ((frame (first-frame env)))
          (scan (frame-variables frame)
                (frame-values frame)))))
  (env-loop env))

;;
;; zie deel 1a p. 34
;;
(define (define-variable! var val env)
  (let ((frame (first-frame env)))
    (define (scan vars vals)
      (cond ((null? vars)
             (add-binding-to-frame! var val frame))
            ((eq? var (car vars))
             (set-car! vals val))
            (else (scan (cdr vars) (cdr vals)))))
    (scan (frame-variables frame)
          (frame-values frame))))

;;
;; zie deel 1a p. 35
;;
(define (setup-environment)
  (let ((initial-env
         (extend-environment (primitive-procedure-names)
                             (primitive-procedure-objects)
                             the-empty-environment)))
    (define-variable! 'true true initial-env)
    (define-variable! 'false false initial-env)
    initial-env))

;;
;; zie deel 1a p. 36
;;
(define (primitive-procedure? proc)
  (tagged-list? proc 'primitive))

(define (primitive-implementation proc) (cadr proc))

(define primitive-procedures
  (list (list 'car car)
        (list 'cdr cdr)
        (list 'cons cons)
        (list 'null? null?)
        (list '+ +)
        (list '* *)
        (list '= =)
        (list '- -)
        (list 'make-ring make-ring)
        (list 'display-ring display-ring)
        ;; more primitives
        ))

(define (primitive-procedure-names)
  (map car
       primitive-procedures))

(define (primitive-procedure-objects)
  (map (lambda (proc) (list 'primitive (cadr proc)))
       primitive-procedures))

;;
;; zie deel 1a p. 37
;;
(define (apply-primitive-procedure proc args)
  (apply-in-underlying-scheme
   (primitive-implementation proc) args))

;;
;; zie deel 1a p. 38
;;
(define input-prompt ";;; M-Eval input:")
(define output-prompt ";;; M-Eval value:")

(define (driver-loop)
  (prompt-for-input input-prompt)
  (let ((input (read)))
    (let ((output (eval input the-global-environment)))
      (announce-output output-prompt)
      (user-print output)))
  (driver-loop))

(define (prompt-for-input string)
  (newline) (newline) (display string) (newline))

(define (announce-output string)
  (newline) (display string) (newline))

(define (user-print object)
  (if (compound-procedure? object)
      (display (list 'compound-procedure
                     (procedure-parameters object)
                     (procedure-body object)
                     '<env>))
      (display object)))

(define the-global-environment (setup-environment))
(driver-loop)