#lang racket

;; The Where-Am-I helper functions:
;; originally written by Nick Parlante

;;
;;  the 2-D POINT type  (x and y coordinates)
;;  impelemented as a list length 2
;;
;;  the CIRCLE type (a radius and a center point)
;;  implemented as a list length 2-- first element is the radius and
;;  the second is the center point
;;
;;  For convenience, I do not insist that you treat these as ADT's-
;;  so if you want to use CAR to get the x coordinate, or build you own
;;  circles without going through MAKE-CIRCLE that will be ok.
;; 
;; POINT functions:
;;  make-pt   create a new point
;;  x         get the x coordinate of a point
;;  y         get the y coordinate of a point
;;  dist      return the distance between two points
;;
;; CIRCLE functions
;;  make-circle   create a new circle
;;  radius        get the radius of a circle
;;  center        get the center of a circle
;;  intersect     given two circles, returns a list of the points
;;                of intersection for those circles.
;;                For the purposes of this program I have
;;                bastardized the definition of 'intersect' a little
;;                to give better results when the measurements are
;;                inexact.  Don't worry about that, just use the points
;;                returned.  Someone who is interested in Math or Geometry
;;                might be interested to see how I compute the intersection.

(define (make-pt x y) 
  (list x y))

(define (x pt) 
  (car pt))

(define (y pt) 
  (cadr pt))

(define (dist pt1 pt2) 
  (let ((dx (- (x pt1) (x pt2)))
        (dy (- (y pt1) (y pt2))))
    (sqrt (+ (* dx dx) (* dy dy)))))

;;
;; 2D vector operations - used by the intersection function
;; vectors are a lot like points.  You won't need these.
;; 

(define (add v1 v2)
  (list (+ (car v1) (car v2))
	(+ (cadr v1) (cadr v2))))

(define (sub v1 v2)
  (list (- (car v1) (car v2))
	(- (cadr v1) (cadr v2))))

(define (len v)
  (sqrt (+ (* (car v) (car v))
	   (* (cadr v) (cadr v)))))

(define (scale v factor)
  (list (* (car v) factor) 
	(* (cadr v) factor)))

(define (normalize v)
  (scale (list (- (cadr v)) (car v)) (/ (len v))))


(define (make-circle radius center) 
  (list radius center))

(define (radius circle) 
  (car circle))

(define (center circle) 
  (cadr circle))

;;
;; Function: intersect
;; -------------------
;; Return a list of the points of intersection of the two circles.
;; The circles may not have the same center point
;;

(define (intersect circle1 circle2)
  (if (equal? (center circle1) (center circle2))
      (error "Intersect cannont handle circles with the same center point.")
      (let* ((c1 (center circle1))
	     (r1 (radius circle1))
	     (c2 (center circle2))
	     (r2 (radius circle2))
	     (d (dist c1 c2)))
      ;; first check to see if the circles are too far apart to intersect,
      ;; or if one circle is within another.
	(if (or (> d (+ r1 r2)) (> r1 (+ d r2)) (> r2 (+ d r1)))
	    ;; if there is no real intersection, use the closest tangent points on each
	    ;; circle.  This is the bastardization above.
	    (list (add c1 (scale (sub c2 c1) (/ r1 d)))  ;; c1-> towards c2
		  (add c2 (scale (sub c1 c2) (/ r2 d)))) ;; c2-> towards c1
    ;;otherwise the circles intersect normally, and I did some hairy
    ;;geometry to show that the following computes the two points
    ;;of intersection.
    (let* ((r12 (* r1 r1))
           (r22 (* r2 r2))
           (d2 (* d d))
           (d1 (/ (+ r12 (- r22) d2) 2 d))
           (h (sqrt (- r12 (* d1 d1))))
           (towards (scale (sub c2 c1) (/ d1 d))) ;;vector c1->c2
           (perp (scale (normalize towards) h)))
      (list (add c1 (add towards perp))
            (add c1 (add towards (scale perp -1)))))))))

;;
;; Function: prefix-of-list
;; ------------------------
;; Accepts the incoming list and returns one
;; with the same first k elements and nothing more.
;;

(define (prefix-of-list ls k)
  (if (or (zero? k) (null? ls)) '()
      (cons (car ls) (prefix-of-list (cdr ls) (- k 1)))))

;;
;; Function: partition
;; -------------------
;; Takes a pivot and a list and produces a pair two lists.
;; The first of the two lists contains all of those element less than the 
;; pivot, and the second contains everything else.  Notice that
;; the first list pair every produced is (() ()), and as the
;; recursion unwinds exactly one of the two lists gets a new element
;; cons'ed to the front of it.  
;; 

(define (ratedPoints-comp< p1 p2) (< (car p1) (car p2) ))

(define (partition pivot num-list comp)
  (if (null? num-list) '(() ())
      (let ((split-of-rest (partition pivot (cdr num-list) comp )))
	(if (comp (car num-list) pivot)
	    (list (cons (car num-list) (car split-of-rest)) (cadr split-of-rest))
	    (list (car split-of-rest) (cons (car num-list) (car (cdr split-of-rest))))))))

;;
;; Function: quicksort
;; -------------------
;; Implements the quicksort algorithm to sort lists of numbers from
;; high to low.  If a list is of length 0 or 1, then it is trivially
;; sorted.  Otherwise, we partition to cdr of the list around the car
;; to generate two lists: those in the cdr that are smaller than the car,
;; and those in the cdr that are greater than or equal to the car.  
;; We then recursively quicksort the two lists, and then splice everything
;; together in the proper order.
;;

(define (quicksort num-list comp)
  (if (<= (length num-list) 1) num-list
      (let ((split (partition (car num-list) (cdr num-list) comp )))
	(append (quicksort (car split) comp) 
		(list (car num-list)) 
		(quicksort (cadr split) comp)))))

;;
;; Function: remove
;; ----------------
;; Generates a copy of the specified list, except that all
;; instances that match the specified elem in the equal? sense
;; are excluded.
;;

(define (remove elem ls)
  (cond ((null? ls) '())
	((equal? (car ls) elem) (remove elem (cdr ls)))
	(else (cons (car ls) (remove elem (cdr ls))))))
                  
;; 
;; Function: all-guesses
;; ---------------------
;; Given a list of distances and a list of stars, return a list of all
;; the possible guesses.  A single guess is a list of circles which pairs
;; each distance with one of the stars.
;; 

(define (all-guesses distances stars)
  (if (or (null? distances) (null? stars)) '(())
      (apply append 
	     (map (lambda (star)
		    (map (lambda (pair) 
			   (cons (list (car distances) star) pair))
			 (all-guesses (cdr distances) (remove star stars))
			 )
		    )
		  stars))))

(define *distances-1* '(2.65 5.55 5.25))
(define *stars-1* '((0 0) (4 6) (10 0) (7 4) (12 5)))

(define *distances-2* '(2.5 11.65 7.75))
(define *stars-2* '((0 0) (4 4) (10 0)))

;; 
;; Include your code below.. make sure
;; write and test each function independently.  This
;; will require that you repeatedly type in
;; (load "where-am-i.scm") at the command prompt, allowing
;; it to override exisiting definitions and including
;; the most recently implemented into the lot.
;;


;;1 intersection-points
(define (intersection-points points-list) (if (null?  points-list) '()
(append (apply append (map (lambda (circle2) (intersect (car points-list) circle2 ) )
             (cdr points-list)
             )) (intersection-points (cdr points-list) )
        )
                                              ) )

;;2 distance-product
(define (distance-product point points-list)
  (apply * (map
            (lambda (t) (if (equal? t point) 1 (dist t point)))
                points-list))
  ) 

;;3 rate-points
(define (rate-points points-list) (map
                                   (lambda (elem) (list (distance-product elem points-list) elem))
                                   points-list))

;;4 sort-points
(define (sort-points rated-list) (quicksort rated-list ratedPoints-comp< ))

;;5 clumped-points
(define (clumped-points points-list) (map cadr
                                          (prefix-of-list (sort-points (rate-points points-list))
                                           (quotient (length points-list) 2)
                                           )
                                          ))

;;6 average-point
(define (average-point points-list) (let ((avg-pt (list (/ (apply + (map car points-list)) (length points-list))
                                                        (/ (apply + (map cadr points-list)) (length points-list)) )))
                                      (list (distance-product avg-pt points-list)
                                                           avg-pt)
                                      )
                                      )

;;7 best-estimate
(define (best-estimate guesses-list)    (average-point(clumped-points (intersection-points guesses-list))) )


;;8 where-am-i

 

(define (generate-all-guess distances-list stars-list)(if (or (> (length distances-list) (length stars-list))
                                                              (or (null? stars-list) (null? distances-list) )
                                                              ) '()
                                                          (append
                                                           (if (null? (cdr distances-list) )
                                                                          (map  (lambda (star) (list (list (car distances-list) star))) stars-list )
              
                                                           (apply append  (map
                                                                    (lambda (distance)
                                                                        (map
                                                                                (lambda (one-guess)
                                                                                     (cons (list distance (car stars-list)) one-guess) )
                                                                                          (generate-all-guess (remove  distance distances-list) (cdr stars-list) )
                                                                                                 )
                                                                                             )
                                                                                     distances-list ) )  )
                                                                  (generate-all-guess distances-list (cdr stars-list) )
                                                           )
                                                       ))

(generate-all-guess '(1 2) '( (0 0) (3 0) (2 0)) )
(generate-all-guess '(1 ) '((3 0)) )

(define (where-am-i distances-list stars-list)
  (let ((answer-list (quicksort (map best-estimate (generate-all-guess distances-list stars-list))  ratedPoints-comp<)))
    (if (< (length answer-list) 5)
        answer-list
        (prefix-of-list answer-list 5)
        )
    )
  )

(best-estimate '((1 (0 0)) (1 (2 0)) (0.1 (1 0))))
(where-am-i '(2.5 11.65 7.75) '((0 0) (4 4) (10 0)))
(where-am-i '(2.65 5.55 5.25) '((0 0) (4 6) (10 0) (7 4) (12 5)))
