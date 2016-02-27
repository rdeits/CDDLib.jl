import MathProgBase
importall MathProgBase.SolverInterface

type Cdd_LPSolutionData{T<:MyType}
  filename::Cdd_DataFileType
  objective::Cdd_LPObjectiveType
  solver::Cdd_LPSolverType
  m::Cdd_rowrange
  d::Cdd_colrange
  numbtype::Cdd_NumberType

  LPS::Cdd_LPStatusType
  # the current solution status
  optvalue::T
  # optimal value
  sol::Cdd_Arow{T}
  # primal solution
  dsol::Cdd_Arow{T}
  # dual solution
  nbindex::Cdd_colindex
  # current basis represented by nonbasic indices
  re::Cdd_rowrange
  # row index as a certificate in the case of inconsistency
  se::Cdd_colrange
  # col index as a certificate in the case of dual inconsistency
  pivots0::Clong
  pivots1::Clong
  pivots2::Clong
  pivots3::Clong
  pivots4::Clong
  # pivots[0]=setup (to find a basis), pivots[1]=PhaseI or Criss-Cross,
  # pivots[2]=Phase II, pivots[3]=Anticycling, pivots[4]=GMP postopt.
  total_pivots::Clong
end

function dd_freelpsolution(lp::Ptr{Cdd_LPSolutionData{Cdouble}})
  @ddf_ccall FreeLPSolution Void (Ptr{Cdd_LPSolutionData{Cdouble}},) lp
end
function dd_freelpsolution(lp::Ptr{Cdd_LPSolutionData{GMPRational}})
  @dd_ccall FreeLPSolution Void (Ptr{Cdd_LPSolutionData{GMPRational}},) lp
end

type CDDLPSolution{T<:MyType}
  sol::Ptr{Cdd_LPSolutionData{T}}

  function CDDLPSolution(sol::Ptr{Cdd_LPSolutionData{T}})
    s = new(sol)
    finalizer(s, myfree)
    s
  end
end

CDDLPSolution{T<:MyType}(sol::Ptr{Cdd_LPSolutionData{T}}) = CDDLPSolution{T}(sol)

function myfree(sol::CDDLPSolution)
  dd_freelpsolution(sol.sol)
end

function status(sol::CDDLPSolution)
  [:Undecided, :Optimal, :Inconsistent,
   :DualInconsistent, :StructInconsistent, :StructDualInconsistent,
   :Unbounded, :DualUnbounded][unsafe_load(sol.sol).LPS+1]
end
function simplestatus(sol::CDDLPSolution)
  [:Undecided, :Optimal, :Infeasible,
   :Unbounded, :Infeasible, :Unbounded,
   :Unbounded, :Infeasible][unsafe_load(sol.sol).LPS+1]
end

function getobjval(sol::CDDLPSolution{GMPRational})
  Rational{Int}(unsafe_load(sol.sol).optvalue)
end
function getobjval(sol::CDDLPSolution{Cdouble})
  unsafe_load(sol.sol).optvalue
end

function getsolution(sol::CDDLPSolution{GMPRational})
  soldata = unsafe_load(sol.sol)
  solutiontmp = myconvert(Array, soldata.sol, soldata.d)
  solution = Array{Rational{BigInt}}(solutiontmp)[2:end]
  myfree(solutiontmp)
  solution
end
function getsolution(sol::CDDLPSolution{Cdouble})
  soldata = unsafe_load(sol.sol)
  solutiontmp = myconvert(Array, soldata.sol, soldata.d)
  solutiontmp[2:end]
end

function getreducedcosts(sol::CDDLPSolution{GMPRational})
  soldata = unsafe_load(sol.sol)
  # -1 because there is the objective
  dualsolutiontmp = myconvert(Array, soldata.dsol, soldata.m-1)
  dualsolution = Array{Rational{BigInt}}(dualsolutiontmp)
  myfree(dualsolutiontmp)
  dualsolution
end
function getreducedcosts(sol::CDDLPSolution{Cdouble})
  soldata = unsafe_load(sol.sol)
  # -1 because there is the objective
  println(soldata.m)
  myconvert(Array, soldata.dsol, soldata.m-1)
end

type Cdd_LPData{T<:MyType}
  filename::Cdd_DataFileType
  objective::Cdd_LPObjectiveType
  solver::Cdd_LPSolverType
  Homogeneous::Cdd_boolean
  # The first column except for the obj row is all zeros.
  m::Cdd_rowrange
  d::Cdd_colrange
  A::Cdd_Amatrix{T}
  B::Cdd_Bmatrix{T}
  objrow::Cdd_rowrange
  rhscol::Cdd_colrange
  numbtype::Cdd_NumberType
  eqnumber::Cdd_rowrange
  # the number of equalities
  equalityset::Cdd_rowset

  redcheck_extensive::Cdd_boolean
  # Apply the extensive redundancy check.
  ired::Cdd_rowrange
  # the row index for the redundancy checking
  redset_extra::Cdd_rowset
  # a set of rows that are newly recognized redundan by the extensive search.
  redset_accum::Cdd_rowset
  # the accumulated set of rows that are recognized redundant
  posset_extra::Cdd_rowset
  # a set of rows that are recognized non-linearity

  lexicopivot::Cdd_boolean
  # flag to use the lexicogrphic pivot rule (symbolic perturbation).

  LPS::Cdd_LPStatusType
  # the current solution status
  m_alloc::Cdd_rowrange
  # the allocated row size of matrix A
  d_alloc::Cdd_colrange
  # the allocated col size of matrix A
  optvalue::T
  # optimal value
  sol::Cdd_Arow{T}
  # primal solution
  dsol::Cdd_Arow{T}
  # dual solution
  nbindex::Cdd_colindex
  # current basis represented by nonbasic indices
  re::Cdd_rowrange
  # row index as a certificate in the case of inconsistency
  se::Cdd_colrange
  #col index as a certificate in the case of dual inconsistency
  pivots0::Clong
  pivots1::Clong
  pivots2::Clong
  pivots3::Clong
  pivots4::Clong
  # pivots[0]=setup (to find a basis), pivots[1]=PhaseI or Criss-Cross,
  #  pivots[2]=Phase II, pivots[3]=Anticycling, pivots[4]=GMP postopt.
  total_pivots::Clong
  use_given_basis::Cint
  # switch to indicate the use of the given basis
  given_nbindex::Cdd_colindex
  # given basis represented by nonbasic indices
  starttime::Ctime_t
  endtime::Ctime_t
end

function dd_freelpdata(lp::Ptr{Cdd_LPData{Cdouble}})
  @ddf_ccall FreeLPData Void (Ptr{Cdd_LPData{Cdouble}},) lp
end
function dd_freelpdata(lp::Ptr{Cdd_LPData{GMPRational}})
  @dd_ccall FreeLPData Void (Ptr{Cdd_LPData{GMPRational}},) lp
end

type CDDLP{T<:MyType}
  lp::Ptr{Cdd_LPData{T}}

  function CDDLP(lp::Ptr{Cdd_LPData{T}})
    l = new(lp)
    finalizer(l, myfree)
    l
  end
end

CDDLP{T<:MyType}(lp::Ptr{Cdd_LPData{T}}) = CDDLP{T}(lp)

function myfree(lp::CDDLP)
  dd_freelpdata(lp.lp)
end

function dd_matrix2feasibility(matrix::Ptr{Cdd_MatrixData{Cdouble}})
  err = Ref{Cdd_ErrorType}(0)
  lp = (@ddf_ccall Matrix2Feasibility Ptr{Cdd_LPData{Cdouble}} (Ptr{Cdd_MatrixData{Cdouble}}, Ref{Cdd_ErrorType}) matrix err)
  myerror(err[])
  lp
end
function dd_matrix2feasibility(matrix::Ptr{Cdd_MatrixData{GMPRational}})
  err = Ref{Cdd_ErrorType}(0)
  lp = (@dd_ccall Matrix2Feasibility Ptr{Cdd_LPData{GMPRational}} (Ptr{Cdd_MatrixData{GMPRational}}, Ref{Cdd_ErrorType}) matrix err)
  myerror(err[])
  lp
end
function matrix2feasibility(matrix::CDDInequalityMatrix)
  CDDLP(dd_matrix2feasibility(matrix.matrix))
end

function dd_matrix2lp(matrix::Ptr{Cdd_MatrixData{Cdouble}})
  err = Ref{Cdd_ErrorType}(0)
  lp = (@ddf_ccall Matrix2LP Ptr{Cdd_LPData{Cdouble}} (Ptr{Cdd_MatrixData{Cdouble}}, Ref{Cdd_ErrorType}) matrix err)
  myerror(err[])
  lp
end
function dd_matrix2lp(matrix::Ptr{Cdd_MatrixData{GMPRational}})
  err = Ref{Cdd_ErrorType}(0)
  lp = (@dd_ccall Matrix2LP Ptr{Cdd_LPData{GMPRational}} (Ptr{Cdd_MatrixData{GMPRational}}, Ref{Cdd_ErrorType}) matrix err)
  myerror(err[])
  lp
end
function matrix2lp(matrix::CDDInequalityMatrix)
  CDDLP(dd_matrix2lp(matrix.matrix))
end

function dd_lpsolve(lp::Ptr{Cdd_LPData{Cdouble}}, solver::Cdd_LPSolverType)
  err = Ref{Cdd_ErrorType}(0)
  found = (@ddf_ccall LPSolve Cdd_ErrorType (Ptr{Cdd_LPData{Cdouble}}, Cdd_LPSolverType, Ref{Cdd_ErrorType}) lp solver err)
  myerror(err[])
  found
end
function dd_lpsolve(lp::Ptr{Cdd_LPData{GMPRational}}, solver::Cdd_LPSolverType)
  err = Ref{Cdd_ErrorType}(0)
  found = (@dd_ccall LPSolve Cdd_ErrorType (Ptr{Cdd_LPData{GMPRational}}, Cdd_LPSolverType, Ref{Cdd_ErrorType}) lp solver err)
  myerror(err[])
  found
end
function lpsolve(lp::CDDLP, solver::Symbol=:DualSimplex)
  found = dd_lpsolve(lp.lp, solver == :DualSimplex ? dd_DualSimplex : dd_CrissCross)
  if !Bool(found)
    error("LP could not be solved")
  end
end

function dd_copylpsolution(lp::Ptr{Cdd_LPData{Cdouble}})
  @ddf_ccall CopyLPSolution Ptr{Cdd_LPSolutionData{Cdouble}} (Ptr{Cdd_LPData{Cdouble}},) lp
end
function dd_copylpsolution(lp::Ptr{Cdd_LPData{GMPRational}})
  @dd_ccall CopyLPSolution Ptr{Cdd_LPSolutionData{GMPRational}} (Ptr{Cdd_LPData{GMPRational}},) lp
end
function copylpsolution(lp::CDDLP)
  CDDLPSolution(dd_copylpsolution(lp.lp))
end
