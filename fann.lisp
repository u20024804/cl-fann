(defpackage :fann
  (:use :cl :cffi)
  (:export :make-net :make-shortcut-net :cascade-train-on-file
           :train-on-file :load-from-file :save-to-file :run-net :load-fann))

(in-package :fann)

(define-foreign-library libfann (:unix "libfann.so.2"))

(defun load-fann ()
  (use-foreign-library libfann))

(handler-case (load-fann)
  (load-foreign-library-error (expr)
    (declare (ignore expr))
    (format t "~%======================================================")
    (format t "~%~%~%Voce nao tem fann instalada, terminando compilação.~%~%")
    (format t "~%======================================================")
    #+sbcl(sb-ext:quit)))

(defcfun "fann_create_standard_array" :pointer (num_layers :int) (layers :pointer))

(defcfun "fann_create_shortcut_array" :pointer (num_layers :int) (layers :pointer))


(defstruct fann-net fann-net inputs outputs)

(defun make-net (&rest camadas)
  (with-foreign-object (layers :int (length camadas))
    (loop for i in camadas
       for j from 0
       do (setf (mem-aref layers :int j) i))
    (make-fann-net :fann-net (fann-create-standard-array (length camadas) layers)
                   :inputs (first camadas)
                   :outputs (first (last camadas)))))

(defun make-shortcut-net (&rest camadas)
  (with-foreign-object (layers :int (length camadas))
    (loop for i in camadas
       for j from 0
       do (setf (mem-aref layers :int j) i))
    (make-fann-net :fann-net (fann-create-shortcut-array (length camadas) layers)
                   :inputs (first camadas)
                   :outputs (first (last camadas)))))

(defcfun "fann_create_from_file" :pointer (filename :string))
(defcfun "fann_get_num_input" :int (net :pointer))
(defcfun "fann_get_num_output" :int (net :pointer))

(defun load-from-file (filename)
  "Carrega uma rede preconfigurada e pretreinada de um arquivo."
  (let ((net (fann-create-from-file filename)))
    (make-fann-net :fann-net net
                   :inputs (fann-get-num-input net)
                   :outputs (fann-get-num-output net))))

(defcfun "fann_save" :int (net :pointer) (filename :string))

(defun save-to-file (net file)
  "Salva uma rede num arquivo"
  (fann-save (fann-net-fann-net net) file))

(defcfun "fann_train_on_file" :void
  (net :pointer)
  (file :string)
  (max-epochs :int)
  (epochs-between-reports :int)
  (desired-error :float))

(defun train-on-file (net file max-e ebr de)
  (fann-train-on-file (fann-net-fann-net net) file max-e ebr de))

(defcfun "fann_cascadetrain_on_file" :void
  (net :pointer)
  (file :string)
  (max-neurons :int)
  (neurons-between-reports :int)
  (desired-error :float))

(defun cascade-train-on-file (net file max-e ebr de)
  (fann-cascadetrain-on-file (fann-net-fann-net net) file max-e ebr de))


(defcfun "fann_run" :pointer (net :pointer) (inputs :pointer))

(defun run-net (net inputs)
  (with-foreign-object (input :float (fann-net-inputs net))
    (loop for i from 0
       for j in inputs
       do (setf (mem-aref input :float i) (coerce j 'float)))
    (let ((res (fann-run (fann-net-fann-net net) input)))
      (loop for i from 0 to (1- (fann-net-outputs net))
         collect (mem-aref res :float i)))))
           
                         
