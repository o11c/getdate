#include "Python.h"
#include "xtime.h"

static PyObject *ErrorObject;
extern time_t get_date(char *, struct timeb *);

/* ----------------------------------------------------- */

static char getdate_getdate__doc__[] =
""
;

static PyObject *
getdate_getdate(PyObject *self /* Not used */, PyObject *args)
{
    (void)self;
	time_t result;
    char *buf = 0;
    if (!PyArg_ParseTuple(args, "s", &buf))
    {
    	return NULL;
    }
    result = get_date(buf, NULL);
    if (result == -1)
    {
    	PyErr_SetString(ErrorObject, "invalid time expression");
        return NULL;
	}
	
	return PyLong_FromLong(result);
}

/* List of methods defined in the module */

static struct PyMethodDef getdate_methods[] = {
	{"getdate",	(PyCFunction)getdate_getdate, METH_VARARGS, getdate_getdate__doc__},
	{NULL,	 (PyCFunction)NULL, 0, NULL}		/* sentinel */
};


/* Initialization function for the module (*must* be called initgetdate) */

static char getdate_module_documentation[] = 
""
;

__attribute__((visibility("default")))
void
initgetdate()
{
	PyObject *m, *d;

	/* Create the module and add the functions */
	m = Py_InitModule4("getdate", getdate_methods,
		getdate_module_documentation,
		(PyObject*)NULL,PYTHON_API_VERSION);

	/* Add some symbolic constants to the module */
	d = PyModule_GetDict(m);
	ErrorObject = PyString_FromString("getdate.error");
	PyDict_SetItemString(d, "error", ErrorObject);

	/* XXXX Add constants here */
	
	/* Check for errors */
	if (PyErr_Occurred())
		Py_FatalError("can't initialize module getdate");
}

